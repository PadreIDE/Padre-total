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

our $VERSION = '0.38';
our @ISA     = 'Wx::StyledTextCtrl';

our %mode = (
	WIN  => Wx::wxSTC_EOL_CRLF,
	MAC  => Wx::wxSTC_EOL_CR,
	UNIX => Wx::wxSTC_EOL_LF,
);

# mapping for mime-type to the style name in the share/styles/default.yml file
our %MIME_STYLE = (
	'application/x-perl' => 'perl',
	'text/x-patch'       => 'diff',
	'text/x-makefile'    => 'make',
	'text/x-yaml'        => 'yaml',
	'text/css'           => 'css',
	'application/x-php'  => 'perl',    # temporary solution
);

my $data;
my $data_name;
my $data_private;
my $width;

sub new {
	my $class    = shift;
	my $notebook = shift;

	# Create the underlying Wx object
	my $self   = $class->SUPER::new($notebook);
	my $config = $self->main->ide->config;

	# TODO: Make this suck less
	$data = data( $config->editor_style );

	# Set the code margins a little larger than the default.
	# This seems to noticably reduce eye strain.
	$self->SetMarginLeft(2);
	$self->SetMarginRight(0);

	# Clear out all the other margins
	$self->SetMarginWidth( 0, 0 );
	$self->SetMarginWidth( 1, 0 );
	$self->SetMarginWidth( 2, 0 );

	Wx::Event::EVT_RIGHT_DOWN( $self, \&on_right_down );
	Wx::Event::EVT_LEFT_UP( $self, \&on_left_up );
	Wx::Event::EVT_CHAR( $self, \&on_char );
	Wx::Event::EVT_SET_FOCUS( $self, \&on_focus );

	if ( $config->editor_wordwrap ) {
		$self->SetWrapMode(Wx::wxSTC_WRAP_WORD);
	}

	$self->SetDropTarget( Padre::Wx::FileDropTarget->new( $self->main ) );

	return $self;
}

sub main {
	return $_[0]->GetGrandParent;
}

sub data {
	my $name    = shift;
	my $private = shift;

	return $data if not defined $name;
	return $data if defined $data and $name eq $data_name;

	my $file
		= $private
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

# most of this should be read from some external files
# but for now we use this if statement
sub padre_setup {
	my $self = shift;

	Padre::Util::debug("before setting the lexer");
	$self->SetLexer( $self->{Document}->lexer );

	# the next line will change the ESC key to cut the current selection
	# See: http://www.yellowbrain.com/stc/keymap.html
	#$self->CmdKeyAssign(Wx::wxSTC_KEY_ESCAPE, 0, Wx::wxSTC_CMD_CUT);

	# This is supposed to be Wx::wxSTC_CP_UTF8
	# and Wx::wxUNICODE or wxUSE_UNICODE should be on
	$self->SetCodePage(65001);

	my $mimetype = $self->{Document}->get_mimetype;
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

	$self->setup_style_from_config('plain');

	return;
}

sub padre_setup_style {
	my $self = shift;
	my $name = shift;
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
	my ( $self, $name ) = @_;

	foreach my $k ( keys %{ $data->{$name}->{colors} } ) {
		my $f = 'Wx::' . $k;
		if ($k =~ /^PADRE_/) {
			$f = 'Padre::Constant::' . $k;
		}
		no strict "refs";    ## no critic
		my $v = eval { $f->() };
		if ( $@ ) {
			warn "invalid key '$k'\n";
			next;
		}

		my $colors = $data->{$name}->{colors}->{$k};
		if ( exists $colors->{foreground} ) {
			$self->StyleSetForeground( $f->(), _color( $colors->{foreground} ) );
		}
		if ( exists $colors->{background} ) {
			$self->StyleSetBackground( $f->(), _color( $colors->{background} ) );
		}
		if ( exists $colors->{bold} ) {
			$self->StyleSetBold( $f->(), $colors->{bold} );
		}
		if ( exists $colors->{italics} ) {
			$self->StyleSetItalic( $f->(), $colors->{italic} );
		}
		if ( exists $colors->{eolfilled} ) {
			$self->StyleSetEOLFilled( $f->(), $colors->{eolfilled} );
		}
		if ( exists $colors->{underlined} ) {
			$self->StyleSetUnderline( $f->(), $colors->{underline} );
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

sub highlight_braces {
	my ($self) = @_;

	$self->BraceHighlight( -1, -1 );    # Wx::wxSTC_INVALID_POSITION
	my $pos1 = $self->GetCurrentPos;
	my $chr  = chr( $self->GetCharAt($pos1) );

	my @braces = ( '{', '}', '(', ')', '[', ']' );
	if ( not grep { $chr eq $_ } @braces ) {
		if ( $pos1 > 0 ) {
			$pos1--;
			$chr = chr( $self->GetCharAt($pos1) );
			return unless grep { $chr eq $_ } @braces;
		}
	}

	my $pos2 = $self->BraceMatch($pos1);
	return if abs( $pos1 - $pos2 ) < 2;

	return if $pos2 == -1;    #Wx::wxSTC_INVALID_POSITION  #????

	$self->BraceHighlight( $pos1, $pos2 );

	return;
}

# currently if there are 9 lines we set the margin to 1 width and then
# if another line is added it is not seen well.
# actually I added some improvement allowing a 50% growth in the file
# and requireing a min of 2 width
sub show_line_numbers {
	my ( $self, $on ) = @_;

	# premature optimization, caching the with that was on the 3rd place at load time
	# as timed my Deve::NYTProf
	$width ||= $self->TextWidth( Wx::wxSTC_STYLE_LINENUMBER, "m" );    # width of a single character
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
		$self->SetMarginType( 2, Wx::wxSTC_MARGIN_SYMBOL );    # margin number 2 for symbols
		$self->SetMarginMask( 2, Wx::wxSTC_MASK_FOLDERS );     # set up mask for folding symbols
		$self->SetMarginSensitive( 2, 1 );                     # this one needs to be mouse-aware
		$self->SetMarginWidth( 2, 16 );                        # set margin 2 16 px wide

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

					# TODO check this (cf. ~/contrib/samples/stc/edit.cpp from wxWidgets)
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
	if ( defined $config->editor_font && length $config->editor_font > 0 ) {    # empty default...
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
	my $prefix = $self->GetTextRange( $first, $pos );    # line from beginning to current position
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
# FIXME/TODO: needs some refactoring
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
			or length($prev_indent) < length($indent) && $prev_content =~ /{\s*$/ )
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

		# TODO: What should happen in this case?
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

# when the focus is received by the editor
sub on_focus {
	my ( $self, $event ) = @_;
	my $doc = Padre::Current->document;

	Padre::Util::debug( "Focus received file: " . ( $doc->filename || '' ) );

	my $main = $self->main;

	# to show/hide the document specific Perl menu
	$main->refresh_menu;

	# update the directory listing
	if ( $main->has_directory ) {
		if ( $main->menu->view->{directory}->IsChecked ) {
			$main->directory->update_gui;
		}
	}


	if ( $self->needs_manual_colorize ) {

		#Padre::Util::debug("needs manual");
		$doc->colorize;
		$self->needs_manual_colorize(0);
	} elsif ( $self->needs_stc_colorize ) {

		#Padre::Util::debug("needs stc");
		$doc->remove_color;
		$self->Colourise( 0, $self->GetLength );
		$self->needs_stc_colorize(0);
	}

	$event->Skip(1);    # so the cursor will show up
	return;
}

sub on_char {
	my ( $self, $event ) = @_;

	my $doc = $self->{Document};
	if ( $doc->can('event_on_char') ) {
		$doc->event_on_char( $self, $event );
	}

	$event->Skip;
	return;
}

sub on_left_up {
	my ( $self, $event ) = @_;

	my $text = $self->GetSelectedText;
	if ( Padre::Constant::WXGTK and defined $text and $text ne '' ) {

		# Only on X11 based platforms
		Wx::wxTheClipboard->UsePrimarySelection(1);
		$self->put_text_to_clipboard($text);
		Wx::wxTheClipboard->UsePrimarySelection(0);
	}

	my $doc = $self->{Document};
	if ( $doc->can('event_on_left_up') ) {
		$doc->event_on_left_up( $self, $event );
	}

	$event->Skip;
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

	my $menu = Wx::Menu->new;
	my $undo = $menu->Append( Wx::wxID_UNDO, '' );
	if ( not $self->CanUndo ) {
		$undo->Enable(0);
	}
	my $z = Wx::Event::EVT_MENU(
		$main,    # Ctrl-Z
		$undo,
		sub {
			my $editor = Padre::Current->editor;
			if ( $editor->CanUndo ) {
				$editor->Undo;
			}
			return;
		},
	);
	my $redo = $menu->Append( Wx::wxID_REDO, '' );
	if ( not $self->CanRedo ) {
		$redo->Enable(0);
	}

	Wx::Event::EVT_MENU(
		$main,    # Ctrl-Y
		$redo,
		sub {
			my $editor = Padre::Current->editor;
			if ( $editor->CanRedo ) {
				$editor->Redo;
			}
			return;
		},
	);
	$menu->AppendSeparator;

	my $selection_exists = 0;
	my $id               = $main->notebook->GetSelection;
	if ( $id != -1 ) {
		my $text = $main->notebook->GetPage($id)->GetSelectedText;
		if ( defined($text) && length($text) > 0 ) {
			$selection_exists = 1;
		}
	}

	my $sel_all = $menu->Append( Wx::wxID_SELECTALL, Wx::gettext("Select all\tCtrl-A") );
	if ( not $main->notebook->GetPage($id)->GetTextLength > 0 ) {
		$sel_all->Enable(0);
	}
	Wx::Event::EVT_MENU(
		$main,    # Ctrl-A
		$sel_all,
		sub { \&text_select_all(@_) },
	);
	$menu->AppendSeparator;

	my $copy = $menu->Append( Wx::wxID_COPY, Wx::gettext("&Copy\tCtrl-C") );
	if ( not $selection_exists ) {
		$copy->Enable(0);
	}
	Wx::Event::EVT_MENU(
		$main,    # Ctrl-C
		$copy,
		sub {
			Padre::Current->editor->Copy;
		}
	);

	my $cut = $menu->Append( Wx::wxID_CUT, Wx::gettext("Cu&t\tCtrl-X") );
	if ( not $selection_exists ) {
		$cut->Enable(0);
	}
	Wx::Event::EVT_MENU(
		$main,    # Ctrl-X
		$cut,
		sub {
			Padre::Current->editor->Cut;
		}
	);

	my $paste = $menu->Append( Wx::wxID_PASTE, Wx::gettext("&Paste\tCtrl-V") );
	my $text = $self->get_text_from_clipboard();

	if ( length($text) && $main->notebook->GetPage($id)->CanPaste ) {
		Wx::Event::EVT_MENU(
			$main,    # Ctrl-V
			$paste,
			sub {
				Padre::Current->editor->Paste;
			},
		);
	} else {
		$paste->Enable(0);
	}

	$menu->AppendSeparator;

	my $commentToggle = $menu->Append( -1, Wx::gettext("&Toggle Comment\tCtrl-Shift-C") );
	Wx::Event::EVT_MENU(
		$main,
		$commentToggle,
		sub {
			Padre::Wx::Main::on_comment_toggle_block(@_);
		},
	);
	my $comment = $menu->Append( -1, Wx::gettext("&Comment Selected Lines\tCtrl-M") );
	Wx::Event::EVT_MENU(
		$main, $comment,
		sub {
			Padre::Wx::Main::on_comment_out_block(@_);
		},
	);
	my $uncomment = $menu->Append( -1, Wx::gettext("&Uncomment Selected Lines\tCtrl-Shift-M") );
	Wx::Event::EVT_MENU(
		$main,
		$uncomment,
		sub {
			Padre::Wx::Main::on_uncomment_block(@_);
		},
	);

	$menu->AppendSeparator;

	if ( $event->isa('Wx::MouseEvent')
		and $self->main->ide->config->editor_folding )
	{
		my $mousePos         = $event->GetPosition;
		my $line             = $self->LineFromPosition( $self->PositionFromPoint($mousePos) );
		my $firstPointInLine = $self->PointFromPosition( $self->PositionFromLine($line) );

		if (   $mousePos->x < $firstPointInLine->x
			&& $mousePos->x > ( $firstPointInLine->x - 18 ) )
		{
			my $fold = $menu->Append( -1, Wx::gettext("Fold all") );
			Wx::Event::EVT_MENU(
				$main, $fold,
				sub {
					$_[0]->current->editor->fold_all;
				},
			);
			my $unfold = $menu->Append( -1, Wx::gettext("Unfold all") );
			Wx::Event::EVT_MENU(
				$main, $unfold,
				sub {
					$_[0]->current->editor->unfold_all;
				},
			);
			$menu->AppendSeparator;
		}
	}

	Wx::Event::EVT_MENU(
		$main,
		$menu->Append( -1, Wx::gettext("&Split window") ),
		sub {
			Padre::Wx::Main::on_split_window(@_);
		},
	);

	my $doc = $self->{Document};
	if ( $doc->can('event_on_right_down') ) {
		$doc->event_on_right_down( $self, $menu, $event );
	}

	# Let the plugins have a go
	$self->main->ide->plugin_manager->on_context_menu( $doc, $self, $menu, $event );

	if ( $event->isa('Wx::MouseEvent') ) {
		$self->PopupMenu( $menu, $event->GetX, $event->GetY );
	} else {    #Wx::CommandEvent
		$self->PopupMenu( $menu, 50, 50 );    # TODO better location
	}
}

sub on_mouse_motion {
	my $self  = shift;
	my $event = shift;
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

sub put_text_to_clipboard {
	my ( $self, $text ) = @_;
	@_ = ();    # Feeble attempt to kill Scalars Leaked

	Wx::wxTheClipboard->Open;
	Wx::wxTheClipboard->SetData( Wx::TextDataObject->new($text) );
	Wx::wxTheClipboard->Close;

	return;
}

sub get_text_from_clipboard {

	# This is to be used as a method even if we don't use $self!
	# my $self = shift;
	my $text = '';
	Wx::wxTheClipboard->Open;
	if ( Wx::wxTheClipboard->IsSupported(Wx::wxDF_TEXT) ) {
		my $data = Wx::TextDataObject->new;
		if ( Wx::wxTheClipboard->GetData($data) ) {
			$text = $data->GetText;
		}
	}
	Wx::wxTheClipboard->Close;
	return $text;
}

# Comment or uncomment text depending on the first selected line.
# This is the most coherent way to handle mixed blocks (commented and
# uncommented lines).
sub comment_toggle_lines {
	my ( $self, $begin, $end, $str ) = @_;
	if ( _get_line_by_number( $self, $begin ) =~ /\s*$str/ ) {
		uncomment_lines(@_);
	} else {
		comment_lines(@_);
	}
}

# $editor->comment_lines($begin, $end, $str);
# $str is either # for perl or // for Javascript, etc.
# $str might be ['<--', '-->] for html
sub comment_lines {
	my ( $self, $begin, $end, $str ) = @_;

	$self->BeginUndoAction;
	if ( ref $str eq 'ARRAY' ) {
		my $pos = $self->PositionFromLine($begin);
		$self->InsertText( $pos, $str->[0] );
		$pos = $self->GetLineEndPosition($end);
		$self->InsertText( $pos, $str->[1] );
	} else {
		for my $line ( $begin .. $end ) {

			# insert $str (# or //)
			my $pos = $self->PositionFromLine($line);
			$self->InsertText( $pos, $str );
		}
	}
	$self->EndUndoAction;
	return;
}

#
# $editor->uncomment_lines($begin, $end, $str);
#
# uncomment lines $begin..$end
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
		my $length = length $str;
		for my $line ( $begin .. $end ) {
			my $first = $self->PositionFromLine($line);
			my $last  = $first + $length;
			my $text  = $self->GetTextRange( $first, $last );
			if ( $text eq $str ) {
				$self->SetSelection( $first, $last );
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

	my ( $newline_type, $convert_to ) = $doc->newline_type;

	$self->SetEOLMode( $mode{$newline_type} );

	if ( defined $doc->{original_content} ) {
		$self->SetText( $doc->{original_content} );
	}
	$self->EmptyUndoBuffer;
	if ($convert_to) {
		my $file = $doc->filename;
		warn "Converting $file to $convert_to";
		$self->ConvertEOLs( $mode{$newline_type} );
	}

	$doc->{newline_type} = $newline_type;

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
	} else {
		return;
	}

	$self->insert_text($text);

	return;
}

sub vertically_align {
	my $editor = shift;

	# Get the selected lines
	my $begin = $editor->LineFromPosition( $editor->GetSelectionStart );
	my $end   = $editor->LineFromPosition( $editor->GetSelectionEnd );
	if ( $begin == $end ) {
		$_[0]->error( Wx::gettext("You must select a range of lines") );
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
		$_[0]->error( Wx::gettext("First character of selection must be a non-word character to align") );
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

sub needs_stc_colorize {
	if ( defined $_[1] ) {
		$_[0]->{needs_stc_colorize} = $_[1];
	}
	return $_[0]->{needs_stc_colorize};
}

1;

# Copyright 2008-2009 The Padre development team as listed in Padre.pm.
# LICENSE
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl 5 itself.
