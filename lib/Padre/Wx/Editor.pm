package Padre::Wx::Editor;

use 5.008;
use strict;
use warnings;
use YAML::Tiny       ();
use Padre::Util      ();
use Padre::Wx        ();
use Padre::Documents ();
use Wx::DND;

use base 'Wx::StyledTextCtrl';

our $VERSION = '0.19';

my $data;
my $width;

sub new {
	my( $class, $parent ) = @_;

	my $self = $class->SUPER::new( $parent );
#	$self->UsePopUp(0);
	$data = data();
#	$self->SetMouseDwellTime(1000); # off: Wx::SC_TIME_FOREVER

	$self->SetMarginWidth(0, 0);
	$self->SetMarginWidth(1, 0);
	$self->SetMarginWidth(2, 0);

	Wx::Event::EVT_RIGHT_DOWN( $self, \&on_right_down );
	Wx::Event::EVT_LEFT_UP(  $self, \&on_left_up );
	
	if ( Padre->ide->config->{editor_use_wordwrap} ) {
		$self->SetWrapMode( Wx::wxSTC_WRAP_WORD );
	}
	$self->SetDropTarget(Padre::Wx::DNDFilesDropTarget->new(Padre->ide->wx->main_window));	
	return $self;
}

sub data {
	unless ( defined $data ) {
		$data = YAML::Tiny::LoadFile(
			Padre::Util::sharefile( 'styles', 'default.yml' )
		);
	}
	return $data;
}


# most of this should be read from some external files
# but for now we use this if statement
sub padre_setup {
	my ($self) = @_;

	$self->SetLexer( $self->{Document}->lexer );
#	 $self->Colourise(0, $self->GetTextLength);

	# the next line will change the ESC key to cut the current selection
	# See: http://www.yellowbrain.com/stc/keymap.html
	#$self->CmdKeyAssign(Wx::wxSTC_KEY_ESCAPE, 0, Wx::wxSTC_CMD_CUT);

	$self->SetCodePage(65001); # which is supposed to be Wx::wxSTC_CP_UTF8
	# and Wx::wxUNICODE() or wxUSE_UNICODE should be on

	my $mimetype = $self->{Document}->mimetype;
    if ($mimetype eq 'application/x-perl') {
        $self->padre_setup_style('perl');
    } elsif ( $mimetype eq 'application/x-pasm' ) {
        $self->padre_setup_style('pasm');
    } elsif ($mimetype) {
		# setup some default colouring
		# for the time being it is the same as for Perl
        $self->padre_setup_style('perl');
	} else {
		# if mimetype is not known, then no colouring for now
		# but mimimal conifuration should apply here too
        $self->padre_setup_plain;
	}

    return;
}

sub padre_setup_plain {
	my $self = shift;

	my $font = Wx::Font->new( 10, Wx::wxTELETYPE, Wx::wxNORMAL, Wx::wxNORMAL );

	$self->SetFont( $font );

	$self->StyleSetFont( Wx::wxSTC_STYLE_DEFAULT, $font );

	$self->StyleClearAll();

	foreach my $k (keys %{ $data->{plain}{forgrounds} }) {
		$self->StyleSetForeground( $k, _colour( $data->{plain}{foregrounds}{$k} ) );
	}
	
	#$self->StyleSetBold(12,  1);

	# Apply tag style for selected lexer (blue)
	$self->StyleSetSpec( Wx::wxSTC_H_TAG, "fore:#0000ff" );

	if ( $self->can('SetLayoutDirection') ) {
		$self->SetLayoutDirection( Wx::wxLayout_LeftToRight );
	}

	return;
}

sub padre_setup_style {
	my ($self, $name) = @_;

	$self->padre_setup_plain;

	no strict "refs";
	foreach my $k ( keys %{ $data->{$name}{colors} }) {
		my $f = 'Wx::' . $k;
		my $v = eval {$f->()};
		if ($@) {
			$f = 'Px::' . $k;
			$v = eval {$f->()};
			if ($@) {
				warn "invalid key '$k'\n";
				next;
			}
		}

		$self->StyleSetForeground( $f->(), _colour($data->{$name}{colors}{$k}) );
	}

	$self->StyleSetBackground(34, _colour($data->{$name}{brace_highlight}));

	return;
}

sub _colour {
	my $rgb = shift;
	my @c = map {hex($_)} $rgb =~ /(..)(..)(..)/;
	return Wx::Colour->new(@c)
}

sub highlight_braces {
	my ($self) = @_;

	$self->BraceHighlight(-1, -1); # Wx::wxSTC_INVALID_POSITION
	my $pos1  = $self->GetCurrentPos;
	my $chr = chr($self->GetCharAt($pos1));

	my @braces = ( '{', '}', '(', ')', '[', ']');
	if (not grep {$chr eq $_} @braces) {
		if ($pos1 > 0) {
			$pos1--;
			$chr = chr($self->GetCharAt($pos1));
			return unless grep {$chr eq $_} @braces;
		}
	}
	
	my $pos2  = $self->BraceMatch($pos1);
	return if abs($pos1-$pos2) < 2;

	return if $pos2 == -1;   #Wx::wxSTC_INVALID_POSITION  #????
	
	$self->BraceHighlight($pos1, $pos2);

	return;
}


# currently if there are 9 lines we set the margin to 1 width and then
# if another line is added it is not seen well.
# actually I added some improvement allowing a 50% growth in the file
# and requireing a min of 2 width
sub show_line_numbers {
	my ($self, $on) = @_;

	# premature optimization, caching the with that was on the 3rd place at load time
	# as timed my Deve::NYTProf
	$width ||= $self->TextWidth(Wx::wxSTC_STYLE_LINENUMBER, "9"); # width of a single character
	if ($on) {
		my $n = 1 + List::Util::max (2, length ($self->GetLineCount * 2));
		my $width = $n * $width;
		$self->SetMarginWidth(0, $width);
		$self->SetMarginType(0, Wx::wxSTC_MARGIN_NUMBER);
	} else {
		$self->SetMarginWidth(0, 0);
		$self->SetMarginType(0, Wx::wxSTC_MARGIN_NUMBER);
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

	if ( $on ) {
		# Setup a margin to hold fold markers
		$self->SetMarginType(2, Wx::wxSTC_MARGIN_SYMBOL); # margin number 2 for symbols
		$self->SetMarginMask(2, Wx::wxSTC_MASK_FOLDERS);  # set up mask for folding symbols
		$self->SetMarginSensitive(2, 1);                  # this one needs to be mouse-aware
		$self->SetMarginWidth(2, 16);                     # set margin 2 16 px wide

		# define folding markers
		my $w = Wx::Colour->new("white");
		my $b = Wx::Colour->new("black");
		$self->MarkerDefine(Wx::wxSTC_MARKNUM_FOLDEREND,     Wx::wxSTC_MARK_BOXPLUSCONNECTED,  $w, $b);
		$self->MarkerDefine(Wx::wxSTC_MARKNUM_FOLDEROPENMID, Wx::wxSTC_MARK_BOXMINUSCONNECTED, $w, $b);
		$self->MarkerDefine(Wx::wxSTC_MARKNUM_FOLDERMIDTAIL, Wx::wxSTC_MARK_TCORNER,  $w, $b);
		$self->MarkerDefine(Wx::wxSTC_MARKNUM_FOLDERTAIL,    Wx::wxSTC_MARK_LCORNER,  $w, $b);
		$self->MarkerDefine(Wx::wxSTC_MARKNUM_FOLDERSUB,     Wx::wxSTC_MARK_VLINE,    $w, $b);
		$self->MarkerDefine(Wx::wxSTC_MARKNUM_FOLDER,        Wx::wxSTC_MARK_BOXPLUS,  $w, $b);
		$self->MarkerDefine(Wx::wxSTC_MARKNUM_FOLDEROPEN,    Wx::wxSTC_MARK_BOXMINUS, $w, $b);

		# This would be nice but the colour used for drawing the lines is 
		# Wx::wxSTC_STYLE_DEFAULT, i.e. usually black and therefore quite
		# obtrusive...
		# $self->SetFoldFlags( Wx::wxSTC_FOLDFLAG_LINEBEFORE_CONTRACTED | Wx::wxSTC_FOLDFLAG_LINEAFTER_CONTRACTED );

		# activate 
		$self->SetProperty('fold' => 1);

		Wx::Event::EVT_STC_MARGINCLICK(
		    $self,
    		Wx::wxID_ANY,
    		sub {
        		my ( $editor, $event ) = @_;
        		if ( $event->GetMargin() == 2 ) {
            		my $line_clicked = $editor->LineFromPosition( $event->GetPosition() );
            		my $level_clicked = $editor->GetFoldLevel($line_clicked);
                    # TODO check this (cf. ~/contrib/samples/stc/edit.cpp from wxWidgets)
            		#if ( $level_clicked && wxSTC_FOLDLEVELHEADERFLAG) > 0) {
                		$editor->ToggleFold($line_clicked);
            		#}
        		}
    		}
		);
	}
	else {
		$self->SetMarginSensitive(2, 0);
        $self->SetMarginWidth(2, 0);
		# deactivate
        $self->SetProperty('fold' => 1);
	}

	return;
}

sub set_preferences {
	my ($self) = @_;

	my $config = Padre->ide->config;

	$self->show_line_numbers(    $config->{editor_linenumbers}       );
	$self->show_folding(         $config->{editor_codefolding}       );
	$self->SetIndentationGuides( $config->{editor_indentationguides} );
	$self->SetViewEOL(           $config->{editor_eol}               );
	$self->SetViewWhiteSpace(    $config->{editor_whitespaces}       );
	$self->show_currentlinebackground( $config->{editor_currentlinebackground} );

	$self->SetTabWidth( $config->{editor_tabwidth} );
	$self->SetUseTabs(  $config->{editor_use_tabs} );

	return;
}

sub show_currentlinebackground {
	my ($self, $on) = (@_);

	$self->SetCaretLineBackground( Wx::Colour->new(238, 238, 238, 255) );
	$self->SetCaretLineVisible( ( defined($on) && $on ) ? 1 : 0 );

	return;
}

sub show_calltip {
	my ($self) = @_;

	my $config = Padre->ide->config;
	return if not $config->{editor_calltips};


	my $pos    = $self->GetCurrentPos;
	my $line   = $self->LineFromPosition($pos);
	my $first  = $self->PositionFromLine($line);
	my $prefix = $self->GetTextRange($first, $pos); # line from beginning to current position
	   #$prefix =~ s{^.*?((\w+::)*\w+)$}{$1};
	if ($self->CallTipActive) {
		$self->CallTipCancel;
	}

    my $doc = Padre::Documents->current or return;
    my $keywords = $doc->keywords;

	my $regex = join '|', sort {length $a <=> length $b} keys %$keywords;

	my $tip;
	if ( $prefix =~ /($regex)[ (]?$/ ) {
		my $z = $keywords->{$1};
		return if not $z or not ref($z) or ref($z) ne 'HASH';
		$tip = "$z->{cmd}\n$z->{exp}";
	}
	if ($tip) {
		$self->CallTipShow($self->CallTipPosAtStart() + 1, $tip);
	}
	return;
}

# 1) get the white spaces of the previous line and add them here as well
# TODO: 2) after a brace indent one level more than previous line
sub autoindent {
	my ($self) = @_;

	my $config = Padre->ide->config;
	return if not $config->{editor_autoindent} or $config->{editor_autoindent} eq 'no';
	
	my $pos       = $self->GetCurrentPos;
	my $prev_line = $self->LineFromPosition($pos) -1;
	return if $prev_line < 0;

	my $start     = $self->PositionFromLine($prev_line);
	my $end       = $self->GetLineEndPosition($prev_line);
	#my $length    = $self->LineLength($prev_line);
	my $content   = $self->GetTextRange($start, $end);
	#print "'$content'\n";
	my $indent = '';
	if ($content =~ /^(\s+)/) {
		$indent = $1;
	}
	if ($config->{editor_autoindent} eq 'deep' and $content =~ /\{\s*$/) {
		$indent .= "\t";
	}
	if ($indent ne '') {
		$self->InsertText($pos, $indent);
		$self->GotoPos($pos + length($indent));
	}
	
	return;
}

sub on_right_down {
	my ($self, $event) = @_;
	
	my $win = Padre->ide->wx->main_window;
	
# Popup Was: Undo, Redo | Cut, Copy, Paste, Delete | Select All

	my $pos       = $self->GetCurrentPos;
	#my $line      = $self->LineFromPosition($pos);
	#print "right down: $pos\n"; # this is the position of the cursor and not that of the mouse!
	#my $p = $event->GetLogicalPosition;
	#print "x: ", $p->x, "\n";
	
	my $menu = Wx::Menu->new;
	my $undo = $menu->Append( Wx::wxID_UNDO, '' );
	if (not $self->CanUndo) {
		$undo->Enable(0);
	}
	my $z = Wx::Event::EVT_MENU( $win, # Ctrl-Z
		$undo,
		sub {
			my $editor = Padre::Documents->current->editor;
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
	
	Wx::Event::EVT_MENU( $win, # Ctrl-Y
		$redo,
		sub {
			my $editor = Padre::Documents->current->editor;
			if ( $editor->CanRedo ) {
				$editor->Redo;
			}
			return;
		},
	);
	$menu->AppendSeparator;

	my $selection_exists = 0;
	my $id = $win->{notebook}->GetSelection;
	if ( $id != -1 ) {
		my $txt = $win->{notebook}->GetPage($id)->GetSelectedText;
		if ( defined($txt) && length($txt) > 0 ) {
			$selection_exists = 1;
		}
	}

	my $sel_all = $menu->Append( Wx::wxID_SELECTALL, Wx::gettext("Select all\tCtrl-A") );
	if ( not $win->{notebook}->GetPage($id)->GetTextLength > 0 ) {
		$sel_all->Enable(0);
	}
	Wx::Event::EVT_MENU( $win, # Ctrl-A
		$sel_all,
		sub { \&text_select_all(@_) },
	);
	$menu->AppendSeparator;
	
	my $copy = $menu->Append( Wx::wxID_COPY, '' );
	if ( not $selection_exists ) {
		$copy->Enable(0);
	}
	Wx::Event::EVT_MENU( $win, # Ctrl-C
		$copy,
		sub { Padre->ide->wx->main_window->selected_editor->Copy; }
	);

	my $cut = $menu->Append( Wx::wxID_CUT, '' );
	if ( not $selection_exists ) {
		$cut->Enable(0);
	}
	Wx::Event::EVT_MENU( $win, # Ctrl-X
		$cut,
		sub { Padre->ide->wx->main_window->selected_editor->Cut; }
	);

	my $paste = $menu->Append( Wx::wxID_PASTE, '' );
 	my $text  = get_text_from_clipboard();

	if ( length($text) && $win->{notebook}->GetPage($id)->CanPaste ) {
		Wx::Event::EVT_MENU( $win, # Ctrl-V
			$paste,
			sub { Padre->ide->wx->main_window->selected_editor->Paste },
		);
	} else {
		$paste->Enable(0);
	}

	$menu->AppendSeparator;

#	$menu->Append( Wx::wxID_NEW, '' );
	Wx::Event::EVT_MENU( $win,
		$menu->Append( -1, Wx::gettext("&Split window") ),
		\&Padre::Wx::MainWindow::on_split_window,
	);
	if ($event->isa('Wx::MouseEvent')) {
		$self->PopupMenu( $menu, $event->GetX, $event->GetY);
	} else { #Wx::CommandEvent
		$self->PopupMenu( $menu, 50, 50); # TODO better location
	}
}

sub on_left_up {
	my ($self, $event) = @_;

	my $pos       = $self->GetCurrentPos;
	#my $line      = $self->LineFromPosition($pos);
	#print "$pos\n"; # this is the position of the cursor and not that of the mouse!

	#print "left $pos\n";

	$event->Skip();
	return;
}

sub on_mouse_motion {
	my ( $self, $event ) = @_;

	return unless Padre->ide->config->{editor_syntaxcheck};

	my $mousePos = $event->GetPosition;
	my $line = $self->LineFromPosition( $self->PositionFromPoint($mousePos) );
	my $firstPointInLine = $self->PointFromPosition( $self->PositionFromLine($line) );

	if (   $mousePos->x < ( $firstPointInLine->x - 18 )
		&& $mousePos->x > ( $firstPointInLine->x - 36 )
	) {
		$self->CallTipCancel, return unless $self->MarkerGet($line);
		$self->CallTipShow( $self->PositionFromLine($line), $self->{synchk_calltips}->{$line} );
	}
	else {
		$self->CallTipCancel;
	}

	return;
}

sub text_select_all {
	my ( $win, $event ) = @_;

	my $id = $win->{notebook}->GetSelection;
	return if $id == -1;
	$win->{notebook}->GetPage($id)->SelectAll;
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
	my ($win) = @_;

	# find positions
	my $notebook = $win->{notebook};
	my $id   = $notebook->GetSelection;
	my $page = $notebook->GetPage($id);

	undef $page->{selection_mark_start};
	undef $page->{selection_mark_end};
}

sub put_text_to_clipboard {
	my ($txt) = @_;

	Wx::wxTheClipboard->Open;
	Wx::wxTheClipboard->SetData( Wx::TextDataObject->new($txt) );
	Wx::wxTheClipboard->Close;

	return;
}

sub get_text_from_clipboard {
	Wx::wxTheClipboard->Open;
	my $text   = '';
	if ( Wx::wxTheClipboard->IsSupported(Wx::wxDF_TEXT) ) {
		my $data = Wx::TextDataObject->new;
		my $ok   = Wx::wxTheClipboard->GetData($data);
		if ($ok) {
			$text   = $data->GetText;
		}
	}
	Wx::wxTheClipboard->Close;
	return $text;
}

# $editor->comment_lines($begin, $end, $str);
# $str is either # for perl or // for Javascript, etc.
sub comment_lines {
	my ($self, $begin, $end, $str) = @_;

	$self->BeginUndoAction;
	for my $line ($begin .. $end) {
		# insert $str (# or //)
		my $pos = $self->PositionFromLine($line);
		$self->InsertText($pos, $str);
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
	my ($self, $begin, $end, $str) = @_;

	my $length = length $str;
	$self->BeginUndoAction;
	for my $line ($begin .. $end) {
		my $first = $self->PositionFromLine($line);
		my $last  = $first + $length;
		my $text  = $self->GetTextRange($first, $last);
		if ($text eq $str) {
			$self->SetSelection($first, $last);
			$self->ReplaceSelection('');
		}
	}
	$self->EndUndoAction;

	return;
}



1;

# Copyright 2008 Gabor Szabo.
# LICENSE
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl 5 itself.
