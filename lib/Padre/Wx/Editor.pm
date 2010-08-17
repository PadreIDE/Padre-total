package Padre::Wx::Editor;

use 5.008;
use strict;
use warnings;
use YAML::Tiny                ();
use Padre::Constant           ();
use Padre::Util               ();
use Padre::Current            ();
use Padre::Wx                 ();
use Padre::Wx::FileDropTarget ();
use Padre::Logger;

our $VERSION = '0.69';
our @ISA     = 'Wx::StyledTextCtrl';

# End-Of-Line modes:
# MAC is actually Mac classic.
# MAC OS X and later uses UNIX EOLs
#
# Please note that WIN32 is the API. DO NOT change it to that :)
#
our %mode = (
	WIN  => Wx::wxSTC_EOL_CRLF,
	MAC  => Wx::wxSTC_EOL_CR,
	UNIX => Wx::wxSTC_EOL_LF,
);

# mapping for mime-type to the style name in the share/styles/default.yml file
our %MIME_STYLE = (
	'application/x-perl' => 'perl',
	'application/x-psgi' => 'perl',
	'text/x-perlxs'      => 'xs',   # should be in the plugin...
	'text/x-patch'       => 'diff',
	'text/x-makefile'    => 'make',
	'text/x-yaml'        => 'yaml',
	'text/css'           => 'css',
	'application/x-php'  => 'perl', # temporary solution
);

# Karl
# these are the allowed braces for brace highlighting and brace matching
# this has to be subset of  ( ) [ ] { } < > since we use the scintilla
# Brace* methods
# always altern opening and starting braces in the constant
my $BRACES               = '{}[]()';
my $STC_INVALID_POSITION = Wx::wxSTC_INVALID_POSITION;

my $data;
my $data_name;
my $data_private;
my $width;
my $Clipboard_Old = '';

sub new {
	my $class  = shift;
	my $parent = shift;

	# NOTE: This hack is only here because the Preferences dialog uses
	# an editor object for their style preview thingy.
	my $main = $parent;
	while ( not $main->isa('Padre::Wx::Main') ) {
		$main = $main->GetParent;
	}

	# Create the underlying Wx object
	my $lock = $main->lock( 'UPDATE', 'refresh_windowlist' );
	my $self = $class->SUPER::new($parent);

	# TO DO: Make this suck less
	my $config = $main->config;
	$data = data( $config->editor_style );

	# Set the code margins a little larger than the default.
	# This seems to noticably reduce eye strain.
	$self->SetMarginLeft(2);
	$self->SetMarginRight(0);

	# Clear out all the other margins
	$self->SetMarginWidth( 0, 0 );
	$self->SetMarginWidth( 1, 0 );
	$self->SetMarginWidth( 2, 0 );

	# Set word chars to match Perl variables
	$self->SetWordChars( join '', ( '$@%&_:[]{}', 0 .. 9, 'A' .. 'Z', 'a' .. 'z' ) );

	Wx::Event::EVT_RIGHT_DOWN( $self, \&on_right_down );
	Wx::Event::EVT_LEFT_UP( $self, \&on_left_up );
	Wx::Event::EVT_CHAR( $self, \&on_char );
	Wx::Event::EVT_SET_FOCUS( $self, \&on_focus );
	Wx::Event::EVT_MIDDLE_UP( $self, \&on_middle_up );
	Wx::Event::EVT_MOTION( $self, \&on_mouse_moving );
	Wx::Event::EVT_MOUSEWHEEL( $self, \&on_mousewheel );

	# Smart highlighting:
	# Selecting a word or small block of text causes all other occurrences to be highlighted
	# with a round box around each of them
	my @styles = ();
	$self->{styles} = \@styles;
	$self->IndicatorSetStyle( 0, 7 );
	Wx::Event::EVT_STC_DOUBLECLICK( $self, -1, \&on_smart_highlight_begin );
	Wx::Event::EVT_LEFT_DOWN( $self, \&on_smart_highlight_end );
	Wx::Event::EVT_KEY_DOWN( $self, \&on_smart_highlight_end );

	# No more unsafe CTRL-L for you :)
	# CTRL-L or line cut should only work when there is no empty line
	# This prevents the accidental destruction of the clipboard
	$self->CmdKeyClear( ord('L'), Wx::wxSTC_SCMOD_CTRL );

	# Setup EVT_KEY_UP for smart highlighting and non-destructive CTRL-L
	Wx::Event::EVT_KEY_UP( $self, \&on_key_up );

	if ( $config->editor_wordwrap ) {
		$self->SetWrapMode(Wx::wxSTC_WRAP_WORD);
	}

	$self->SetDropTarget( Padre::Wx::FileDropTarget->new( $self->main ) );

	# Disable CTRL keypad -/+. These seem to emit wrong scan codes
	# on some laptop keyboards. (e.g. CTRL-Caps lock is the same as CTRL -)
	# Please see bug #790
	$self->CmdKeyClear( Wx::wxSTC_KEY_SUBTRACT, Wx::wxSTC_SCMOD_CTRL );
	$self->CmdKeyClear( Wx::wxSTC_KEY_ADD,      Wx::wxSTC_SCMOD_CTRL );

	my $green = Wx::Colour->new("green");
	my $red   = Wx::Colour->new("red");
	my $blue  = Wx::Colour->new("blue");

	#NOTE: DO NOT USE "orange" string since it is actually red on win32
	my $orange = Wx::Colour->new( 255, 165, 0 );

	$self->MarkerDefine(
		Padre::Wx::MarkError(),
		Wx::wxSTC_MARK_SMALLRECT,
		$red,
		$red,
	);
	$self->MarkerDefine(
		Padre::Wx::MarkWarn(),
		Wx::wxSTC_MARK_SMALLRECT,
		$orange,
		$orange,
	);
	$self->MarkerDefine(
		Padre::Wx::MarkLocation(),
		Wx::wxSTC_MARK_SMALLRECT,
		$green,
		$green,
	);
	$self->MarkerDefine(
		Padre::Wx::MarkBreakpoint(),
		Wx::wxSTC_MARK_SMALLRECT,
		$blue,
		$blue,
	);

	return $self;
}

sub main {
	$_[0]->GetGrandParent;
}

# convenience accessor method (and to ensure consistency)
# return the Padre::Config instance
sub config {
	$_[0]->main->config;
}

# convenience methods
# return the character at a given position as a perl string
sub get_character_at {
	my ( $self, $pos ) = @_;
	return chr( $self->GetCharAt($pos) );
}




sub data {
	my $name    = shift;
	my $private = shift;

	return $data if not defined $name;
	return $data if defined $data and $name eq $data_name;

	my $file =
		$private
		? File::Spec->catfile(
		Padre::Constant::CONFIG_DIR,
		'styles', "$name.yml"
		)
		: Padre::Util::sharefile( 'styles', "$name.yml" );
	my $tdata;
	eval { $tdata = YAML::Tiny::LoadFile($file); };
	if ($@) {
		warn $@;
	} else {
		$data_name    = $name;
		$data_private = $private;
		$data         = $tdata;
	}
	return $data;
}

# Error Message
sub error {
	my $self = shift;
	my $text = shift;
	Wx::MessageBox(
		$text,
		Wx::gettext("Error"),
		Wx::wxOK,
		$self->main
	);
}

# Most of this should be read from some external files
# but for now we use this if statement
sub padre_setup {
	my $self = shift;

	TRACE("before setting the lexer") if DEBUG;
	$self->SetLexer( $self->{Document}->lexer );

	# the next line will change the ESC key to cut the current selection
	# See: http://www.yellowbrain.com/stc/keymap.html
	#$self->CmdKeyAssign(Wx::wxSTC_KEY_ESCAPE, 0, Wx::wxSTC_CMD_CUT);

	# This is supposed to be Wx::wxSTC_CP_UTF8
	# and Wx::wxUNICODE or wxUSE_UNICODE should be on
	$self->SetCodePage(65001);

	my $mimetype = $self->{Document}->mimetype || 'text/plain';
	if ( $MIME_STYLE{$mimetype} ) {
		$self->padre_setup_style( $MIME_STYLE{$mimetype} );

	} elsif ( $mimetype eq 'text/plain' ) {
		$self->padre_setup_plain;
		my $filename = $self->{Document}->filename || q{};
		if ( $filename and $filename =~ /\.([^.]+)$/ ) {
			my $ext = lc $1;

			# re-setup if file extension is .conf
			$self->padre_setup_style('conf') if $ext eq 'conf';
		}

	} elsif ($mimetype) {

		# setup some default coloring
		# for the time being it is the same as for Perl
		$self->padre_setup_style('padre');
	} else {

		# if mimetype is not known, then no coloring for now
		# but mimimal configuration should apply here too
		$self->padre_setup_plain;
	}

	return;
}

# Called a key is released in the editor
sub on_key_up {
	my ( $self, $event ) = @_;

	# The new behavior for a non-destructive CTRL-L
	if ( $event->GetKeyCode == ord('L') and $event->ControlDown ) {
		my $line = $self->GetLine( $self->GetCurrentLine() );
		if ( $line !~ /^\s*$/ ) {

			# Only cut on non-black lines
			$self->CmdKeyExecute(Wx::wxSTC_CMD_LINECUT);
		} else {

			# Otherwise delete the line
			$self->CmdKeyExecute(Wx::wxSTC_CMD_LINEDELETE);
		}
		$event->Skip(0); # done processing this nothing more to do
		return;
	}

	# Apply smart highlighting when the shift key is down
	if ( $self->main->ide->config->editor_smart_highlight_enable && $event->ShiftDown ) {
		$self->on_smart_highlight_begin($event);
	}

	# Doc specific processing
	my $doc = $self->{Document};
	if ( $doc->can('event_key_up') ) {
		$doc->event_key_up( $self, $event );
	}

	$event->Skip(1); # we need to keep processing this event

}

sub padre_setup_plain {
	my $self   = shift;
	my $config = $self->main->ide->config;
	$self->set_font;
	$self->StyleClearAll;

	if ( defined $data->{plain}->{current_line_foreground} ) {
		$self->SetCaretForeground( _color( $data->{plain}->{current_line_foreground} ) );
	}
	if ( defined $data->{plain}->{currentline} ) {
		if ( defined $config->editor_currentline_color ) {
			if ( $data->{plain}->{currentline} ne $config->editor_currentline_color ) {
				$data->{plain}->{currentline} = $config->editor_currentline_color;
			}
		}
		$self->SetCaretLineBackground( _color( $data->{plain}->{currentline} ) );
	} elsif ( defined $config->editor_currentline_color ) {
		$self->SetCaretLineBackground( _color( $config->editor_currentline_color ) );
	}

	foreach my $k ( keys %{ $data->{plain}->{foregrounds} } ) {
		$self->StyleSetForeground( $k, _color( $data->{plain}->{foregrounds}->{$k} ) );
	}

	# Apply tag style for selected lexer (blue)
	#$self->StyleSetSpec( Wx::wxSTC_H_TAG, "fore:#0000ff" );

	if ( $self->can('SetLayoutDirection') ) {
		$self->SetLayoutDirection(Wx::wxLayout_LeftToRight);
	}

	$self->SetEdgeColumn( $config->editor_right_margin_column );
	$self->SetEdgeMode( $config->editor_right_margin_enable ? Wx::wxSTC_EDGE_LINE : Wx::wxSTC_EDGE_NONE );

	$self->setup_style_from_config('plain');

	return;
}

sub padre_setup_style {
	my $self   = shift;
	my $name   = shift;
	my $config = $self->main->ide->config;

	$self->padre_setup_plain;
	for ( 0 .. Wx::wxSTC_STYLE_DEFAULT ) {
		$self->StyleSetBackground( $_, _color( $data->{$name}->{background} ) );
	}
	$self->setup_style_from_config($name);

	# if mimetype is known, then it might
	# be Perl with in-line POD
	if ( $config->editor_folding and $config->editor_fold_pod ) {
		$self->fold_pod;
	}

	return;
}

sub setup_style_from_config {
	my $self   = shift;
	my $name   = shift;
	my $style  = $data->{$name};
	my $colors = $style->{colors};

	# The selection background (if applicable)
	# (The Scintilla official selection background colour is cc0000)
	if ( $style->{selection_background} ) {
		$self->SetSelBackground( 1, _color( $style->{selection_background} ) );
	}
	if ( $style->{selection_foreground} ) {
		$self->SetSelForeground( 1, _color( $style->{selection_foreground} ) );
	}

	# Set the styles
	foreach my $k ( keys %$colors ) {
		my $v;

		# allow for plain numbers
		if ( $k =~ /^\d+$/ ) {
			$v = $k;
		}

		# but normally, we have Wx:: or PADRE_ constants
		else {
			my $f = 'Wx::' . $k;
			if ( $k =~ /^PADRE_/ ) {
				$f = 'Padre::Constant::' . $k;
			}
			no strict "refs";
			$v = eval { $f->() };
			if ($@) {
				warn "invalid key '$k'\n";
				next;
			}
		}

		my $color = $data->{$name}->{colors}->{$k};
		if ( exists $color->{foreground} ) {
			$self->StyleSetForeground( $v, _color( $color->{foreground} ) );
		}
		if ( exists $color->{background} ) {
			$self->StyleSetBackground( $v, _color( $color->{background} ) );
		}
		if ( exists $color->{bold} ) {
			$self->StyleSetBold( $v, $color->{bold} );
		}
		if ( exists $color->{italics} ) {
			$self->StyleSetItalic( $v, $color->{italic} );
		}
		if ( exists $color->{eolfilled} ) {
			$self->StyleSetEOLFilled( $v, $color->{eolfilled} );
		}
		if ( exists $color->{underlined} ) {
			$self->StyleSetUnderline( $v, $color->{underline} );
		}
	}
}

sub _color {
	my $rgb = shift;
	my @c = ( 0xFF, 0xFF, 0xFF );
	if ( not defined $rgb ) {

		#Carp::cluck("undefined color");
	} elsif ( $rgb =~ /^(..)(..)(..)$/ ) {
		@c = map { hex($_) } ( $1, $2, $3 );
	} else {

		#Carp::cluck("invalid color '$rgb'");
	}
	return Wx::Colour->new(@c);
}





=head2 get_brace_info

Look at a given position in the editor if there is a brace (according to the 
setting editor_braces) before or after, and return the information about the context
It always look first at the character after the position.

	Params:
		pos - the cursor position in the editor [defaults to cursor position) : int
		
	Return:
		undef if no brace, otherwise [brace, actual_pos, is_after, is_opening]
		where:
			brace - the brace char at actual_pos
			actual_pos - the actual position where the brace has been found
			is_after - true iff the brace is after the cursor : boolean
			is_opening - true iff only the brace is an opening one
			
	Examples:

		|{} => should find the { : [0,{,1,1] 
		{|} => should find the } : [1,},1,0]
		{| } => should find the { : [0,{,0,1]

=cut


sub get_brace_info {
	my ( $self, $pos ) = @_;
	$pos = $self->GetCurrentPos unless defined $pos;

	# try the after position first (default one for BraceMatch)
	my $is_after = 1;
	my $brace    = $self->get_character_at($pos);
	my $is_brace = $self->get_brace_type($brace);
	if ( !$is_brace && $pos > 0 ) { # try the before position
		$brace    = $self->get_character_at( --$pos );
		$is_brace = $self->get_brace_type($brace) or return undef;
		$is_after = 0;
	}
	my $is_opening = $is_brace % 2; # odd values are opening
	return [ $pos, $brace, $is_after, $is_opening ];
}


=head2 get_brace_type

Tell if a character is a brace, and if it is an opening or a closing one

	Params:
		char - a character : string
		
	Return:
		int : 0 if this is not a brace, an odd value if it is an opening brace and an even
		one for a closing brace

=cut

my %_cached_braces;

sub get_brace_type {
	my ( $self, $char ) = @_;
	unless (%_cached_braces) {
		my $i = 1; # start from one so that all values are true
		$_cached_braces{$_} = $i++ foreach ( split //, $BRACES );
	}
	my $v = $_cached_braces{$char} or return 0;
	return $v;
}



# some uncorrect behaviour (| is the cursor)
# {} : never highlighted
# { } : always correct
#
#

sub apply_style {
	my ( $self, $style_info ) = @_;
	my %previous_style = %$style_info;
	$previous_style{style} = $self->GetStyleAt( $style_info->{start} );

	$self->StartStyling( $style_info->{start}, 0xFF );
	$self->SetStyling( $style_info->{len}, $style_info->{style} );

	return \%previous_style;
}


my $previous_expr_hiliting_style;

sub highlight_braces {
	my ($self) = @_;

	my $expression_highlighting = $self->config->editor_brace_expression_highlighting;

	# remove current highlighting if any
	$self->BraceHighlight( $STC_INVALID_POSITION, $STC_INVALID_POSITION );
	if ($previous_expr_hiliting_style) {
		$self->apply_style($previous_expr_hiliting_style);
		$previous_expr_hiliting_style = undef;
	}

	my $pos1          = $self->GetCurrentPos;
	my $info1         = $self->get_brace_info($pos1) or return;
	my ($actual_pos1) = @$info1;

	my $actual_pos2 = $self->BraceMatch($actual_pos1);

	#	return if abs( $pos1 - $pos2 ) < 2;

	return if $actual_pos2 == $STC_INVALID_POSITION; #Wx::wxSTC_INVALID_POSITION  #????

	$self->BraceHighlight( $actual_pos1, $actual_pos2 );

	if ($expression_highlighting) {
		my $pos2 = $self->find_matching_brace($pos1) or return;
		my %style = (
			start => $pos1 < $pos2 ? $pos1 : $pos2,
			len => abs( $pos1 - $pos2 ), style => Wx::wxSTC_STYLE_DEFAULT
		);
		$previous_expr_hiliting_style = $self->apply_style( \%style );
	}


	return;
}


=head2 find_matching_brace

Find the position of to the matching brace if any. If the cursor is inside the braces the destination 
will be inside too, same it is outside.

	Params:
		pos - the cursor position in the editor [defaults to cursor position) : int
		
	Return:
		matching_pos - the matching position, or undef if none

=cut

sub find_matching_brace {
	my ( $self, $pos ) = @_;
	$pos = $self->GetCurrentPos unless defined $pos;
	my $info1 = $self->get_brace_info($pos) or return;
	my ( $actual_pos1, $brace, $is_after, $is_opening ) = @$info1;

	my $actual_pos2 = $self->BraceMatch($actual_pos1);
	return if $actual_pos2 == $STC_INVALID_POSITION;
	$actual_pos2++ if $is_after; # ensure is stays inside if origin is inside, same four outside
	return $actual_pos2;
}


=head2 goto_matching_brace

Move the cursor to the matching brace if any. If the cursor is inside the braces the destination 
will be inside too, same it is outside.

	Params:
		pos - the cursor position in the editor [defaults to cursor position) : int
		

=cut

sub goto_matching_brace {
	my ( $self, $pos ) = @_;
	my $pos2 = $self->find_matching_brace($pos) or return;
	$self->GotoPos($pos2);
}

=head2 select_to_matching_brace

Select to the matching opening or closing brace. If the cursor is inside the braces the destination 
will be inside too, same it is outside.

	Params:
		pos - the cursor position in the editor [defaults to cursor position) : int
		


=cut

sub select_to_matching_brace {
	my ( $self, $pos ) = @_;
	$pos = $self->GetCurrentPos unless defined $pos;
	my $pos2 = $self->find_matching_brace($pos) or return;
	my $start = ( $pos < $pos2 ) ? $self->GetSelectionStart() : $self->GetSelectionEnd();
	$self->SetSelection( $start, $pos2 );

}

# currently if there are 9 lines we set the margin to 1 width and then
# if another line is added it is not seen well.
# actually I added some improvement allowing a 50% growth in the file
# and requireing a min of 2 width
sub show_line_numbers {
	my ( $self, $on ) = @_;

	# premature optimization, caching the with that was on the 3rd place at load time
	# as timed my Deve::NYTProf
	$width ||= $self->TextWidth( Wx::wxSTC_STYLE_LINENUMBER, "m" ); # width of a single character
	if ($on) {
		my $n = 1 + List::Util::max( 2, length( $self->GetLineCount * 2 ) );
		my $width = $n * $width;
		$self->SetMarginWidth( 0, $width );
		$self->SetMarginType( 0, Wx::wxSTC_MARGIN_NUMBER );
	} else {
		$self->SetMarginWidth( 0, 0 );
		$self->SetMarginType( 0, Wx::wxSTC_MARGIN_NUMBER );
	}

	return;
}

# Just a placeholder
sub show_symbols {
	my ( $self, $on ) = @_;

	#	$self->SetMarginWidth(1, 0);

	# $self->SetMarginWidth(1, 16);   #margin 1 for symbols, 16 px wide
	# $self->SetMarginType(1, Wx::wxSTC_MARGIN_SYMBOL);

	return;
}

sub show_folding {
	my ( $self, $on ) = @_;

	if ($on) {

		# Setup a margin to hold fold markers
		$self->SetMarginType( 2, Wx::wxSTC_MARGIN_SYMBOL ); # margin number 2 for symbols
		$self->SetMarginMask( 2, Wx::wxSTC_MASK_FOLDERS );  # set up mask for folding symbols
		$self->SetMarginSensitive( 2, 1 );                  # this one needs to be mouse-aware
		$self->SetMarginWidth( 2, 16 );                     # set margin 2 16 px wide

		# define folding markers
		my $w = Wx::Colour->new("white");
		my $b = Wx::Colour->new("black");
		$self->MarkerDefine( Wx::wxSTC_MARKNUM_FOLDEREND,     Wx::wxSTC_MARK_BOXPLUSCONNECTED,  $w, $b );
		$self->MarkerDefine( Wx::wxSTC_MARKNUM_FOLDEROPENMID, Wx::wxSTC_MARK_BOXMINUSCONNECTED, $w, $b );
		$self->MarkerDefine( Wx::wxSTC_MARKNUM_FOLDERMIDTAIL, Wx::wxSTC_MARK_TCORNER,           $w, $b );
		$self->MarkerDefine( Wx::wxSTC_MARKNUM_FOLDERTAIL,    Wx::wxSTC_MARK_LCORNER,           $w, $b );
		$self->MarkerDefine( Wx::wxSTC_MARKNUM_FOLDERSUB,     Wx::wxSTC_MARK_VLINE,             $w, $b );
		$self->MarkerDefine( Wx::wxSTC_MARKNUM_FOLDER,        Wx::wxSTC_MARK_BOXPLUS,           $w, $b );
		$self->MarkerDefine( Wx::wxSTC_MARKNUM_FOLDEROPEN,    Wx::wxSTC_MARK_BOXMINUS,          $w, $b );

		# This would be nice but the color used for drawing the lines is
		# Wx::wxSTC_STYLE_DEFAULT, i.e. usually black and therefore quite
		# obtrusive...
		# $self->SetFoldFlags( Wx::wxSTC_FOLDFLAG_LINEBEFORE_CONTRACTED | Wx::wxSTC_FOLDFLAG_LINEAFTER_CONTRACTED );

		# activate
		$self->SetProperty( 'fold' => 1 );

		Wx::Event::EVT_STC_MARGINCLICK(
			$self, -1,
			sub {
				my ( $editor, $event ) = @_;
				if ( $event->GetMargin() == 2 ) {
					my $line_clicked  = $editor->LineFromPosition( $event->GetPosition() );
					my $level_clicked = $editor->GetFoldLevel($line_clicked);

					# TO DO check this (cf. ~/contrib/samples/stc/edit.cpp from wxWidgets)
					#if ( $level_clicked && wxSTC_FOLDLEVELHEADERFLAG) > 0) {
					$editor->ToggleFold($line_clicked);

					#}
				}
			}
		);
	} else {
		$self->SetMarginSensitive( 2, 0 );
		$self->SetMarginWidth( 2, 0 );

		# deactivate
		$self->SetProperty( 'fold' => 1 );
		$self->unfold_all;
	}

	return;
}

sub set_font {
	my $self   = shift;
	my $config = $self->main->ide->config;
	my $font   = Wx::Font->new( 10, Wx::wxTELETYPE, Wx::wxNORMAL, Wx::wxNORMAL );
	if ( defined $config->editor_font && length $config->editor_font > 0 ) { # empty default...
		$font->SetNativeFontInfoUserDesc( $config->editor_font );
	}
	$self->SetFont($font);
	$self->StyleSetFont( Wx::wxSTC_STYLE_DEFAULT, $font );
	return;
}

sub set_preferences {
	my $self   = shift;
	my $config = $self->main->ide->config;

	$self->show_line_numbers( $config->editor_linenumbers );
	$self->show_folding( $config->editor_folding );
	$self->SetIndentationGuides( $config->editor_indentationguides );
	$self->SetViewEOL( $config->editor_eol );
	$self->SetViewWhiteSpace( $config->editor_whitespace );
	$self->SetCaretLineVisible( $config->editor_currentline );

	$self->padre_setup;

	$self->{Document}->set_indentation_style;

	return;
}

sub show_calltip {
	my $self   = shift;
	my $config = $self->main->ide->config;
	return unless $config->editor_calltips;

	my $pos    = $self->GetCurrentPos;
	my $line   = $self->LineFromPosition($pos);
	my $first  = $self->PositionFromLine($line);
	my $prefix = $self->GetTextRange( $first, $pos ); # line from beginning to current position
	if ( $self->CallTipActive ) {
		$self->CallTipCancel;
	}

	my $doc      = Padre::Current->document or return;
	my $keywords = $doc->keywords;
	my $regex    = join '|', sort { length $a <=> length $b } keys %$keywords;

	my $tip;
	if ( $prefix =~ /(?:^|[^\w\$\@\%\&])($regex)[ (]?$/ ) {
		my $z = $keywords->{$1};
		return if not $z or not ref($z) or ref($z) ne 'HASH';
		$tip = "$z->{cmd}\n$z->{exp}";
	}
	if ($tip) {
		$self->CallTipShow( $self->CallTipPosAtStart() + 1, $tip );
	}
	return;
}

# For auto-indentation (i.e. one more level), we do the following:
# 1) get the white spaces of the previous line and add them here as well
# 2) after a brace indent one level more than previous line
# 3) while doing all this, respect the current (sadly global) indentation settings
# For auto-de-indentation (i.e. closing brace), we remove one level of indentation
# instead.
# FIX ME/TO DO: needs some refactoring
sub autoindent {
	my ( $self, $mode ) = @_;

	my $config = $self->main->ide->config;
	return unless $config->editor_autoindent;
	return if $config->editor_autoindent eq 'no';

	if ( $mode eq 'deindent' ) {
		$self->_auto_deindent($config);
	} else {

		# default to "indent"
		$self->_auto_indent($config);
	}

	return;
}

sub _auto_indent {
	my ( $self, $config ) = @_;

	my $pos       = $self->GetCurrentPos;
	my $prev_line = $self->LineFromPosition($pos) - 1;
	return if $prev_line < 0;

	my $indent_style = $self->{Document}->get_indentation_style;

	my $content = $self->_get_line_by_number($prev_line);
	my $indent = ( $content =~ /^(\s+)/ ? $1 : '' );

	if ( $config->editor_autoindent eq 'deep' and $content =~ /\{\s*$/ ) {
		my $indent_width = $indent_style->{indentwidth};
		my $tab_width    = $indent_style->{tabwidth};
		if ( $indent_style->{use_tabs} and $indent_width != $tab_width ) {

			# do tab compression if necessary
			# - First, convert all to spaces (aka columns)
			# - Then, add an indentation level
			# - Then, convert to tabs as necessary
			my $tab_equivalent = " " x $tab_width;
			$indent =~ s/\t/$tab_equivalent/g;
			$indent .= $tab_equivalent;
			$indent =~ s/$tab_equivalent/\t/g;
		} elsif ( $indent_style->{use_tabs} ) {

			# use tabs only
			$indent .= "\t";
		} else {
			$indent .= " " x $indent_width;
		}
	}
	if ( $indent ne '' ) {
		$self->InsertText( $pos, $indent );
		$self->GotoPos( $pos + length($indent) );
	}

	return;
}

sub _auto_deindent {
	my ( $self, $config ) = @_;

	my $pos  = $self->GetCurrentPos;
	my $line = $self->LineFromPosition($pos);

	my $indent_style = $self->{Document}->get_indentation_style;

	my $content = $self->_get_line_by_number($line);
	my $indent = ( $content =~ /^(\s+)/ ? $1 : '' );

	# This is for } on a new line:
	if ( $config->editor_autoindent eq 'deep' and $content =~ /^\s*\}\s*$/ ) {
		my $prev_line    = $line - 1;
		my $prev_content = ( $prev_line < 0 ? '' : $self->_get_line_by_number($prev_line) );
		my $prev_indent  = ( $prev_content =~ /^(\s+)/ ? $1 : '' );

		# de-indent only in these cases:
		# - same indentation level as prev. line and not a brace on prev line
		# - higher indentation than pr. l. and a brace on pr. line
		if ( $prev_indent eq $indent && $prev_content !~ /^\s*{/
			or length($prev_indent) < length($indent) && $prev_content =~ /\{\s*$/ )
		{
			my $indent_width = $indent_style->{indentwidth};
			my $tab_width    = $indent_style->{tabwidth};
			if ( $indent_style->{use_tabs} and $indent_width != $tab_width ) {

				# do tab compression if necessary
				# - First, convert all to spaces (aka columns)
				# - Then, add an indentation level
				# - Then, convert to tabs as necessary
				my $tab_equivalent = " " x $tab_width;
				$indent =~ s/\t/$tab_equivalent/g;
				$indent =~ s/$tab_equivalent$//;
				$indent =~ s/$tab_equivalent/\t/g;
			} elsif ( $indent_style->{use_tabs} ) {

				# use tabs only
				$indent =~ s/\t$//;
			} else {
				my $indentation_level = " " x $indent_width;
				$indent =~ s/$indentation_level$//;
			}
		}

		# replace indentation of the current line
		$self->GotoPos( $pos - 1 );
		$self->DelLineLeft();
		$pos = $self->GetCurrentPos();
		$self->InsertText( $pos, $indent );
		$self->GotoPos( $self->GetLineEndPosition($line) );
	}

	# this is if the line matches "blahblahSomeText}".
	elsif ( $config->editor_autoindent eq 'deep' and $content =~ /\}\s*$/ ) {

		# TO DO: What should happen in this case?
	}

	return;
}

# given a line number, returns the contents
sub _get_line_by_number {
	my $self    = shift;
	my $line_no = shift;

	my $start = $self->PositionFromLine($line_no);
	my $end   = $self->GetLineEndPosition($line_no);
	return $self->GetTextRange( $start, $end );
}

sub fold_all {
	my ($self) = @_;

	my $lineCount   = $self->GetLineCount;
	my $currentLine = $lineCount;

	while ( $currentLine >= 0 ) {
		if ( ( my $parentLine = $self->GetFoldParent($currentLine) ) > 0 ) {
			if ( $self->GetFoldExpanded($parentLine) ) {
				$self->ToggleFold($parentLine);
				$currentLine = $parentLine;
			} else {
				$currentLine--;
			}
		} else {
			$currentLine--;
		}
	}

	return;
}

sub unfold_all {
	my ($self) = @_;

	my $lineCount   = $self->GetLineCount;
	my $currentLine = 0;

	while ( $currentLine <= $lineCount ) {
		if ( !$self->GetFoldExpanded($currentLine) ) {
			$self->ToggleFold($currentLine);
		}
		$currentLine++;
	}

	return;
}

# When the focus is received by the editor
sub on_focus {
	my $self     = shift;
	my $event    = shift;
	my $main     = $self->main;
	my $document = $main->current->document;
	TRACE( "Focus received file: " . ( $document->filename || '' ) ) if DEBUG;

	# NOTE: The editor focus event fires a LOT, even for trivial things
	# like changing focus to another application and immediately back again,
	# or switching between tools in Padre.
	# Don't do any refreshing here, it is an excessive waste of resources.
	# Instead, put them in the events that ACTUALLY change application state.

	# TO DO
	# This is called even if the mouse is moved away from padre and back again
	# we should restrict some of the updates to cases when we switch from one file to
	# another
	if ( $self->needs_manual_colorize ) {
		TRACE("needs_manual_colorize") if DEBUG;
		my $lock  = $main->lock('UPDATE');
		my $lexer = $self->GetLexer;
		if ( $lexer == Wx::wxSTC_LEX_CONTAINER ) {
			$document->colorize;
		} else {
			$document->remove_color;
			$self->Colourise( 0, $self->GetLength );
		}
		$self->needs_manual_colorize(0);
	} else {
		TRACE("no need to colorize") if DEBUG;
	}

	# NOTE: This is so the cursor will show up
	$event->Skip(1);

	return;
}

sub on_char {
	my ( $self, $event ) = @_;

	my $doc = $self->{Document};
	if ( $doc->can('event_on_char') ) {
		$doc->event_on_char( $self, $event );
	}

	if ( $self->main->ide->{has_Time_HiRes} ) {
		$doc->{last_char_time} = Time::HiRes::time();
	} else {
		$doc->{last_char_time} = time;
	}

	$event->Skip;
	return;
}

sub clear_smart_highlight {
	my $self = shift;

	my @styles = @{ $self->{styles} };
	if ( scalar @styles ) {
		foreach my $style (@styles) {
			$self->StartStyling( $style->{start}, 0xFF );
			$self->SetStyling( $style->{len}, $style->{style} );
		}
		$#{ $self->{styles} } = -1;
	}
}

sub on_smart_highlight_begin {
	my ( $self, $event ) = @_;

	my $selection        = $self->GetSelectedText;
	my $selection_length = length $selection;
	return if $selection_length == 0;

	my $selection_re = quotemeta $selection;
	my $line_count   = $self->GetLineCount;
	my $line_num     = $self->GetCurrentLine;

	# Limits search to C+N..C-N from current line respecting limits ofcourse
	# to optimize CPU usage
	my $NUM_LINES = 400;
	my $from      = ( $line_num - $NUM_LINES <= 0 ) ? 0 : $line_num - $NUM_LINES;
	my $to        = ( $line_count <= $line_num + $NUM_LINES ) ? $line_count : $line_num + $NUM_LINES;

	# Clear previous smart highlights
	$self->clear_smart_highlight;

	# find matching occurrences
	foreach my $i ( $from .. $to ) {
		my $line_start = $self->PositionFromLine($i);
		my $line       = $self->GetLine($i);
		while ( $line =~ /$selection_re/g ) {
			my $start = $line_start + pos($line) - $selection_length;

			push @{ $self->{styles} },
				{
				start => $start,
				len   => $selection_length,
				style => $self->GetStyleAt($start)
				};
		}
	}

	# smart highlight if there are more than one occurrence...
	if ( scalar @{ $self->{styles} } > 1 ) {
		foreach my $style ( @{ $self->{styles} } ) {
			$self->StartStyling( $style->{start}, 0xFF );
			$self->SetStyling( $style->{len}, Wx::wxSTC_STYLE_DEFAULT );
		}
	}

}

sub on_smart_highlight_end {
	my ( $self, $event ) = @_;

	$self->clear_smart_highlight;
	$event->Skip;
}

sub on_left_up {
	my ( $self, $event ) = @_;

	my $config = $self->main->ide->config;

	my $text = $self->GetSelectedText;
	if ( Padre::Constant::WXGTK and defined $text and $text ne '' ) {

		# Only on X11 based platforms
		#		Wx::wxTheClipboard->UsePrimarySelection(1);
		if ( $config->mid_button_paste ) {
			$self->put_text_to_clipboard( $text, 1 );
		} else {
			$self->put_text_to_clipboard($text);
		}

		#		Wx::wxTheClipboard->UsePrimarySelection(0);
	}

	my $doc = $self->{Document};
	if ( $doc->can('event_on_left_up') ) {
		$doc->event_on_left_up( $self, $event );
	}

	$event->Skip;
	return;
}

sub on_mouse_moving {
	my ( $self, $event ) = @_;

	if ( $event->Moving ) {
		my $doc = $self->{Document};
		if ( $doc->can('event_mouse_moving') ) {
			$doc->event_mouse_moving( $self, $event );
		}
	} else {

		# For a drag event...
	}

	$event->Skip;

}

sub on_middle_up {
	my ( $self, $event ) = @_;

	my $config = $self->main->ide->config;

	# TO DO: Sometimes there are unexpected effects when using the middle button.
	# It seems that another event is doing something but not within this module.
	# Please look at ticket #390 for details!

	Wx::wxTheClipboard->UsePrimarySelection(1)
		if $config->mid_button_paste;

	if ( Padre::Constant::WIN32 or ( !$config->mid_button_paste ) ) {
		Padre::Current->editor->Paste;
	}

	my $doc = $self->{Document};
	if ( $doc->can('event_on_middle_up') ) {
		$doc->event_on_middle_up( $self, $event );
	}

	Wx::wxTheClipboard->UsePrimarySelection(0)
		if $config->mid_button_paste;

	if ( $config->mid_button_paste ) {
		$event->Skip;
	} else {
		$event->Skip(0);
	}
	return;
}


sub on_right_down {
	my $self  = shift;
	my $event = shift;
	my $main  = $self->main;
	my $pos   = $self->GetCurrentPos;

	#my $line  = $self->LineFromPosition($pos);
	#print "right down: $pos\n"; # this is the position of the cursor and not that of the mouse!
	#my $p = $event->GetLogicalPosition;
	#print "x: ", $p->x, "\n";

	require Padre::Wx::Menu::RightClick;
	my $menu = Padre::Wx::Menu::RightClick->new( $main, $self, $event );

	if ( $event->isa('Wx::MouseEvent') ) {
		$self->PopupMenu( $menu->wx, $event->GetX, $event->GetY );
	} else { #Wx::CommandEvent
		$self->PopupMenu( $menu->wx, 50, 50 ); # TO DO better location
	}
}

sub on_mouse_motion {
	my $self   = shift;
	my $event  = shift;
	my $config = $self->main->ide->config;

	$event->Skip;
	return unless $config->main_syntaxcheck;

	my $mousePos         = $event->GetPosition;
	my $line             = $self->LineFromPosition( $self->PositionFromPoint($mousePos) );
	my $firstPointInLine = $self->PointFromPosition( $self->PositionFromLine($line) );

	my ( $offset1, $offset2 ) = ( 0, 18 );
	if ( $config->editor_folding ) {
		$offset1 += 18;
		$offset2 += 18;
	}

	if (    $mousePos->x < ( $firstPointInLine->x - $offset1 )
		and $mousePos->x > ( $firstPointInLine->x - $offset2 ) )
	{
		unless ( $self->MarkerGet($line) ) {
			$self->CallTipCancel;
			return;
		}
		$self->CallTipShow(
			$self->PositionFromLine($line),
			$self->{synchk_calltips}->{$line}
		);
	} else {
		$self->CallTipCancel;
	}

	return;
}

# Convert the Ctrl-Scroll behaviour of changing the font size
# to the non-Ctrl behaviour of scrolling.
sub on_mousewheel {
	my $self  = shift;
	my $event = shift;

	# Behave normally if Ctrl isn't down
	unless ( $event->ControlDown and not $self->config->feature_fontsize ) {
		$event->Skip(1);
		return;
	}

	# Behave as if Ctrl wasn't down
	$self->ScrollLines( $event->GetLinesPerAction * int( $event->GetWheelRotation / $event->GetWheelDelta * -1 ) );

	return;
}

sub text_select_all {
	my ( $main, $event ) = @_;

	my $id = $main->notebook->GetSelection;
	return if $id == -1;
	$main->notebook->GetPage($id)->SelectAll;
	return;
}

sub text_selection_mark_start {
	my ($self) = @_;

	# find positions
	$self->{selection_mark_start} = $self->GetCurrentPos;

	# change selection if start and end are defined
	$self->SetSelection(
		$self->{selection_mark_start},
		$self->{selection_mark_end}
	) if defined $self->{selection_mark_end};
}

sub text_selection_mark_end {
	my ($self) = @_;

	$self->{selection_mark_end} = $self->GetCurrentPos;

	# change selection if start and end are defined
	$self->SetSelection(
		$self->{selection_mark_start},
		$self->{selection_mark_end}
	) if defined $self->{selection_mark_start};
}

sub text_selection_clear_marks {
	my $editor = $_[0]->current->editor;
	undef $editor->{selection_mark_start};
	undef $editor->{selection_mark_end};
}

#
# my ($begin, $end) = $self->current_paragraph;
#
# return $begin and $end position of current paragraph.
#
sub current_paragraph {
	my ($editor) = @_;

	my $curpos = $editor->GetCurrentPos;
	my $lineno = $editor->LineFromPosition($curpos);

	# check if we're in between paragraphs
	return ( $curpos, $curpos ) if $editor->GetLine($lineno) =~ /^\s*$/;

	# find the start of paragraph by searching backwards till we find a
	# line with only whitespace in it.
	my $para1 = $lineno;
	while ( $para1 > 0 ) {
		my $line = $editor->GetLine($para1);
		last if $line =~ /^\s*$/;
		$para1--;
	}

	# now, find the end of paragraph by searching forwards until we find
	# only white space
	my $lastline = $editor->GetLineCount;
	my $para2    = $lineno;
	while ( $para2 < $lastline ) {
		$para2++;
		my $line = $editor->GetLine($para2);
		last if $line =~ /^\s*$/;
	}

	# return the position
	my $begin = $editor->PositionFromLine( $para1 + 1 );
	my $end   = $editor->PositionFromLine($para2);
	return ( $begin, $end );
}

sub Paste {
	my $self = shift;

	# Workaround for Copy/Paste bug ticket #390
	my $text = $self->get_text_from_clipboard;

	if ($text) {

		# Conversion of pasted text is really needed since it usually comes
		# with the platform's line endings
		#
		# Please see ticket:589, "Pasting in a UNIX document in win32
		# corrupts it to MIXEd"
		$self->ReplaceSelection( $self->_convert_paste_eols($text) );
	}

	return 1;
}

#
# This method converts line ending based on current document EOL mode
# and the newline type for the current text
#
sub _convert_paste_eols {
	my ( $self, $paste ) = @_;

	my $newline_type = Padre::Util::newline_type($paste);
	my $eol_mode     = $self->GetEOLMode();

	# Handle the 'None' one-liner case
	if ( $newline_type eq 'None' ) {
		$newline_type = $self->main->config->default_line_ending;
	}

	#line endings
	my $CR   = "\015";
	my $LF   = "\012";
	my $CRLF = "$CR$LF";
	my ( $from, $to );

	# From what to convert from?
	if ( $newline_type eq 'WIN' ) {
		$from = $CRLF;
	} elsif ( $newline_type eq 'UNIX' ) {
		$from = $LF;
	} elsif ( $newline_type eq 'MAC' ) {
		$from = $CR;
	}

	# To what to convert to?
	if ( $eol_mode eq Wx::wxSTC_EOL_CRLF ) {
		$to = $CRLF;
	} elsif ( $eol_mode eq Wx::wxSTC_EOL_LF ) {
		$to = $LF;
	} else {

		#must be Wx::wxSTC_EOL_CR
		$to = $CR;
	}

	# Convert only when it is needed
	if ( $from ne $to ) {
		$paste =~ s/$from/$to/g;
	}

	return $paste;
}

sub put_text_to_clipboard {
	my ( $self, $text, $clipboard ) = @_;
	@_ = (); # Feeble attempt to kill Scalars Leaked

	return if $text eq '';

	my $config = $self->main->ide->config;

	$clipboard ||= 0;

	# Backup last clipboard value:
	$self->{Clipboard_Old} = $self->get_text_from_clipboard;

	#         if $self->{Clipboard_Old} ne $self->get_text_from_clipboard;

	Wx::wxTheClipboard->Open;
	Wx::wxTheClipboard->UsePrimarySelection($clipboard)
		if $config->mid_button_paste;
	Wx::wxTheClipboard->SetData( Wx::TextDataObject->new($text) );
	Wx::wxTheClipboard->Close;

	return;
}

sub get_text_from_clipboard {

	my $self = shift;

	my $text = '';
	Wx::wxTheClipboard->Open;
	if ( Wx::wxTheClipboard->IsSupported(Wx::wxDF_TEXT) ) {
		my $data = Wx::TextDataObject->new;
		if ( Wx::wxTheClipboard->GetData($data) ) {
			$text = $data->GetText if defined($data);
		}
	}
	if ( $text eq $self->GetSelectedText ) {
		$text = $self->{Clipboard_Old};
	}

	Wx::wxTheClipboard->Close;
	return $text;
}

# Comment or uncomment text depending on the first selected line.
# This is the most coherent way to handle mixed blocks (commented and
# uncommented lines).
sub comment_toggle_lines {
	my ( $self, $begin, $end, $str ) = @_;

	if ( _get_line_by_number( $self, $begin ) =~ /^\s*\Q$str\E/ ) {
		uncomment_lines(@_);
	} else {
		comment_lines(@_);
	}
}

# $editor->comment_lines($begin, $end, $str);
# $str is either # for perl or // for Javascript, etc.
# $str might be ['<--', '-->] for html
#
# Change: for Single lines comments, it will (un)comment with indent:
# <indent>$comment_characters<space>XXXXXXX
# If someone has idee for commenting Haskell Guards in Single lines,
# (well, ('-- |') is a symbol for haddock.) please fix it.
#
sub comment_lines {
	my ( $self, $begin, $end, $str ) = @_;

	$self->BeginUndoAction;
	if ( ref $str eq 'ARRAY' ) {
		my $pos = $self->PositionFromLine($begin);
		$self->InsertText( $pos, $str->[0] );
		$pos = $self->GetLineEndPosition($end);
		$self->InsertText( $pos, $str->[1] );
	} else {
		## it is not enough, only current position to check :(
		# my $is_first_column = $self->GetColumn( $self->GetCurrentPos ) == 0;
		# if ( $is_first_column && $end > $begin ) {
		# $end--;
		# }

		foreach my $line ( $begin .. $end ) {
			my $text = _get_line_by_number( $self, $line );

			# next if (length($text) == 0);  # should i do this?

			if ( $text =~ /^(\s*)/ ) {
				my $pos = $self->PositionFromLine($line);
				$pos += length($1);
				$self->InsertText( $pos, $str . ' ' );
			}
		}

	}
	$self->EndUndoAction;
	return;
}

#
# $editor->uncomment_lines($begin, $end, $str);
#
# uncomment lines $begin..$end
# Change: see comments for `comment_lines()`
#
sub uncomment_lines {
	my ( $self, $begin, $end, $str ) = @_;

	$self->BeginUndoAction;
	if ( ref $str eq 'ARRAY' ) {
		my $first = $self->PositionFromLine($begin);
		my $last  = $first + length( $str->[0] );
		my $text  = $self->GetTextRange( $first, $last );
		if ( $text eq $str->[0] ) {
			$self->SetSelection( $first, $last );
			$self->ReplaceSelection('');
		}
		$last  = $self->GetLineEndPosition($end);
		$first = $last - length( $str->[1] );
		$text  = $self->GetTextRange( $first, $last );
		if ( $text eq $str->[1] ) {
			$self->SetSelection( $first, $last );
			$self->ReplaceSelection('');
		}
	} else {

		# my $is_first_column = $self->GetColumn( $self->GetCurrentPos ) == 0;
		# if ( $is_first_column && $end > $begin ) {
		# $end--;
		# }
		foreach my $line ( $begin .. $end ) {
			my $text = _get_line_by_number( $self, $line );

			# the first line starting with '#!' can't be uncommented!
			next if ( $line == 0 && $text =~ /^#!/ );

			if ( $text =~ /^(\s*)(\Q$str\E\s*)/ ) {
				my $start = $self->PositionFromLine($line) + length($1);

				$self->SetSelection( $start, $start + length($2) );
				$self->ReplaceSelection('');
			}
		}
	}
	$self->EndUndoAction;

	return;
}

sub fold_pod {
	my ($self) = @_;

	my $currentLine = 0;
	my $lastLine    = $self->GetLineCount;

	while ( $currentLine <= $lastLine ) {
		if ( $self->_get_line_by_number($currentLine) =~ /^=(pod|head)/ ) {
			if ( $self->GetFoldExpanded($currentLine) ) {
				$self->ToggleFold($currentLine);
				my $foldLevel = $self->GetFoldLevel($currentLine);
				$currentLine = $self->GetLastChild( $currentLine, $foldLevel );
			}
			$currentLine++;
		} else {
			$currentLine++;
		}
	}

	return;
}

sub configure_editor {
	my ( $self, $doc ) = @_;

	my $newline_type = $doc->newline_type;

	$self->SetEOLMode( $mode{$newline_type} or $mode{ $self->main->config->default_line_ending } );

	if ( defined $doc->{original_content} ) {
		$self->SetText( $doc->{original_content} );
	}
	$self->EmptyUndoBuffer;

	$doc->{newline_type} = $newline_type;

	# Set the cursor blink rate
	$self->SetCaretPeriod( $self->main->config->editor_cursor_blink );


	return;
}

sub goto_line_centerize {
	$_[0]->goto_pos_centerize( $_[0]->PositionFromLine( $_[1] ) );
}

# borrowed from Kephra
sub goto_pos_centerize {
	my ( $self, $pos ) = @_;

	my $max = $self->GetLength;
	$pos = 0 unless $pos or $pos < 0;
	$pos = $max if $pos > $max;

	$self->SetCurrentPos($pos);
	$self->SearchAnchor;

	my $line = $self->GetCurrentLine;
	$self->ScrollToLine( $line - ( $self->LinesOnScreen / 2 ) );
	$self->EnsureVisible($line);
	$self->EnsureCaretVisible;
	$self->SetSelection( $pos, $pos );
	$self->SetFocus;
}

sub insert_text {
	my ( $self, $text ) = @_;

	my $data = Wx::TextDataObject->new;
	$data->SetText($text);
	my $length = $data->GetTextLength;

	$self->ReplaceSelection('');
	my $pos = $self->GetCurrentPos;
	$self->InsertText( $pos, $text );
	$self->GotoPos( $pos + $length - 1 );

	return;
}

sub insert_from_file {
	my ( $self, $file ) = @_;

	my $text;
	if ( open( my $fh, '<', $file ) ) {
		binmode($fh);
		local $/ = undef;
		$text = <$fh>;
		close $fh;
	} else {
		return;
	}

	$self->insert_text($text);

	return $file;
}

sub vertically_align {
	my $editor = shift;

	# Get the selected lines
	my $begin = $editor->LineFromPosition( $editor->GetSelectionStart );
	my $end   = $editor->LineFromPosition( $editor->GetSelectionEnd );
	if ( $begin == $end ) {
		$editor->error( Wx::gettext("You must select a range of lines") );
		return;
	}
	my @line = ( $begin .. $end );
	my @text = ();
	foreach (@line) {
		my $x = $editor->PositionFromLine($_);
		my $y = $editor->GetLineEndPosition($_);
		push @text, $editor->GetTextRange( $x, $y );
	}

	# Get the align character from the selection start
	# (which must be a non-whitespace non-word character)
	my $start = $editor->GetSelectionStart;
	my $c = $editor->GetTextRange( $start, $start + 1 );
	unless ( defined $c and $c =~ /^[^\s\w]$/ ) {
		$editor->error( Wx::gettext("First character of selection must be a non-word character to align") );
	}

	# Locate the position of the align character,
	# and the position of the earliest whitespace before it.
	my $qc       = quotemeta $c;
	my @position = ();
	foreach (@text) {
		if (/^(.+?)(\s*)$qc/) {
			push @position, [ length("$1"), length("$2") ];
		} else {

			# This line is not a member of the align set
			push @position, undef;
		}
	}

	# Find the latest position of the starting whitespace.
	my $longest = List::Util::max map { $_->[0] } grep {$_} @position;

	# Now lets line them up
	$editor->BeginUndoAction;
	foreach ( 0 .. $#line ) {
		next unless $position[$_];
		my $spaces = $longest - $position[$_]->[0] - $position[$_]->[1] + 1;
		if ( $_ == 0 ) {
			$start = $start + $spaces;
		}
		my $insert = $editor->PositionFromLine( $line[$_] ) + $position[$_]->[0];
		if ( $spaces > 0 ) {
			$editor->InsertText( $insert, ' ' x $spaces );
		} elsif ( $spaces < 0 ) {
			$editor->SetSelection( $insert, $insert - $spaces );
			$editor->ReplaceSelection('');
		}
	}
	$editor->EndUndoAction;

	# Move the selection to the new position
	$editor->SetSelection( $start, $start );

	return;
}

sub needs_manual_colorize {
	if ( defined $_[1] ) {
		$_[0]->{needs_manual_colorize} = $_[1];
	}
	return $_[0]->{needs_manual_colorize};
}

1;

# Copyright 2008-2010 The Padre development team as listed in Padre.pm.
# LICENSE
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl 5 itself.
