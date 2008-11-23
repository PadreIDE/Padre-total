package Padre::Plugin::Vi::Editor;
use strict;
use warnings;

my %subs;

use List::Util   ();
use Padre::Wx    ();
use Padre::Plugin::Vi::CommandLine;

our $VERSION = '0.18';

sub new {
	my ($class, $editor) = @_;
	my $self = bless {}, $class;
	
	$self->{vi_insert_mode} = 0;
	$self->{vi_buffer}      = '';
	$self->{visual_mode}    = 0;
	$self->{editor}         = $editor;

	return $self;
}

sub editor { return $_[0]->{editor} }

$subs{PLAIN} = {

	# movements
	ord('L')      => sub {
		my ($self, $editor) = @_;
		$self->{end_pressed} = 0;
		if ($self->{visual_mode}) {
			$editor->CharRightExtend();
		} else {
			$editor->CharRight;
		}
	},
	Wx::WXK_RIGHT => ord('L'),
	
	ord('H')      => sub {
		my ($self, $editor) = @_;
		$self->{end_pressed} = 0;
		if ($self->{visual_mode}) {
			$editor->CharLeftExtend;
		} else {
			$editor->CharLeft;
		}
	},
	Wx::WXK_LEFT  => ord('H'),
	
	ord('K')     => \&line_up,
	Wx::WXK_UP   => ord('K'),
	ord('J')     => \&line_down,
	Wx::WXK_DOWN => ord('J'),
	
	Wx::WXK_PAGEUP => sub {
		my ($self, $editor) = @_;
		if ($self->{visual_mode}) {
			$editor->PageUpExtend;
		} else {
			$editor->PageUp;
		}
	},
	Wx::WXK_PAGEDOWN => sub {
		my ($self, $editor) = @_;
		if ($self->{visual_mode}) {
			$editor->PageDownExtend;
		} else {
			$editor->PageDown;
		}
	},
	Wx::WXK_HOME => \&goto_beginning_of_line,
	Wx::WXK_END => \&goto_end_of_line,


	# selection
	ord('V')     => sub {
		my ($self, $editor) = @_;
		my $main   = Padre->ide->wx->main_window;
		$editor->text_selection_mark_start($main);
		$self->{visual_mode} = 1;
	},
	### swictch to insert mode
	ord('A')   => sub {  # append
		my ($self, $editor) = @_;
		$self->{vi_insert_mode} = 1;
		# change cursor
	},
	ord('I') => sub { # insert
		my ($self, $editor) = @_;
		$self->{vi_insert_mode} = 1;
		my $pos  = $editor->GetCurrentPos;
		$editor->GotoPos($pos-1);
		# change cursor
	},
	ord('O') => sub { # open below
		my ($self, $editor) = @_;
		$self->{vi_insert_mode} = 1;
		my $line = $editor->GetCurrentLine;
		my $end  = $editor->GetLineEndPosition($line);
		# go to end of line, insert newline
		$editor->GotoPos($end);
		$editor->NewLine;
		# change cursor
	},
	
	ord('D') => sub {
		my ($self, $editor) = @_;
		if ($self->{vi_buffer} =~ /^(\d*)d$/) { # delete current line
			$self->select_text($editor, $1 || 1);
			$editor->Cut;
			# got to first char, remove $count rows
			$self->{vi_buffer} = '';
		} else {
			$self->{vi_buffer} .= 'd';
		}
	},
	
	ord('Y') => sub {
		my ($self, $editor) = @_;
		if ($self->{vi_buffer} =~ /^(\d*)y$/) { # yank current line
			$self->select_text($editor, $1 || 1);
			$editor->Copy;

			# got to first char, remove $count rows
			$self->{vi_buffer} = '';
		} else {
			$self->{vi_buffer} .= 'y';
		}
	},

	### editing from navigation mode
	ord('X') => sub { # delete
		my ($self, $editor) = @_;
		my $pos  = $editor->GetCurrentPos;
		$editor->SetTargetStart($pos);
		my $count = $self->{vi_buffer} || 1;
		$editor->SetTargetEnd($pos + $count);
		$self->{vi_buffer} = '';
		$editor->ReplaceTarget('');
	},
	ord('U') => sub { # undo
		$_[1]->Undo;
	},
	ord('P') => sub { #paste
		my ($self, $editor) = @_;
		my $text = Padre::Wx::Editor::get_text_from_clipboard();
		if ($text =~ /\n/) {
			my $line  = $editor->GetCurrentLine;
			my $start = $editor->PositionFromLine($line+1);
			$editor->GotoPos($start);
		}
		$editor->Paste;
	},
};

$subs{SHIFT} = {
	ord('O') => sub { # open above
		my ($self, $editor) = @_;
		$self->{vi_insert_mode} = 1;
		my $line = $editor->GetCurrentLine;
		my $start = $editor->PositionFromLine($line);
		# go to beginning of line, insert newline, go to previous line
		$editor->GotoPos($start);
		$editor->NewLine;
		$editor->GotoPos($start);
		# change cursor
	},
	ord('J') => sub {
		my $main   = Padre->ide->wx->main_window;
		$main->on_join_lines;
	},
	ord('P') => sub { #paste above
		my ($self, $editor) = @_;
		my $text = Padre::Wx::Editor::get_text_from_clipboard();
		if ($text =~ /\n/) {
			my $line  = $editor->GetCurrentLine;
			my $start = $editor->PositionFromLine($line);
			$editor->GotoPos($start);
		} else {
			my $pos = $editor->GetCurrentPos;
			$editor->GotoPos($pos-1);
		}
		$editor->Paste;
	},
	ord('4') => \&goto_end_of_line, # Shift-4 is $   End
	ord('6') => \&goto_beginning_of_line, # Shift-6 is ^   Home
};

$subs{COMMAND} = {
	ord('N') => sub { # autocompletion
		print "Ctrl-N $_[0]\n";
		my $main   = Padre->ide->wx->main_window;
		$main->on_autocompletition;
	},
};

# returning the value that will be given to $event->Skip()
sub key_down {
	my ($self, $mod, $code) = @_;

	if ($code == Wx::WXK_ESCAPE) {
		$self->{vi_insert_mode} = 0;
		$self->{vi_buffer}      = '';
		$self->{visual_mode}    = 0;
		return 0;
	}

	if ($self->{vi_insert_mode}) {
		return 1;
	}

# list of keys we don't want to implement but pass back to the STC to handle
#	my %skip = map { $_ => 1 }
#		(Wx::WXK_PAGEDOWN, Wx::WXK_HOME);
#	
#	if ($skip{$code}) {
#		return 1;
#	}
#

	# remove the bit ( Wx::wxMOD_META) set by Num Lock being pressed on Linux
	$mod = $mod & (Wx::wxMOD_ALT() + Wx::wxMOD_CMD() + Wx::wxMOD_SHIFT());
	
	if ($code == ord(';') and $mod == Wx::wxMOD_SHIFT) { # shift-; also know as :
		Padre::Plugin::Vi::CommandLine->show_prompt();
		return 0;
	}


	my $modifier = (  $mod == Wx::wxMOD_SHIFT() ? 'SHIFT' 
	               :  $mod == Wx::wxMOD_CMD()   ? 'COMMAND'
	               :                              'PLAIN');

	if (my $thing = $subs{$modifier}{$code}) {
		my $sub;
		if (not ref $thing) {
			if ($subs{$modifier}{ $thing } and ref $subs{$modifier}{ $thing } and ref $subs{$modifier}{ $thing } eq 'CODE') {
				$sub = $subs{$modifier}{ $thing };
			} else {
				warn "Invalid entry in 'subs' hash  in code '$thing' referenced from '$code'";
			}
		} elsif (ref $subs{$modifier}{$code} eq 'CODE') {
			$sub = $thing;
		} else {
			warn "Invalid entry in 'subs' hash for code '$code'";
		}
		
		if ($sub) {
			$sub->($self, $self->editor);
		}
		return 0 ;
	} 

	if (ord('0') <= $code and $code <= ord('9')) {
		$self->{vi_buffer} .= chr($code);
		return 0;
	}
	
	# left here to easily find extra keys we still need to implement:
	printf("k '%s' '%s', '%s'\n", $mod, $code, 
		(30 < $code and $code < 128 ? chr($code) : ''));
	return 0;
}


sub line_down {
	my ($self, $editor) = @_;
	if ($self->{visual_mode}) {
		$editor->LineDownExtend;
		return;
	}
	#$editor->LineDown; # is this broken?
	my $pos  = $editor->GetCurrentPos;
	my $line = $editor->LineFromPosition($pos);
	my $last_line = $editor->LineFromPosition(length $editor->GetText);
	if ($line < $last_line) {
		line_up_down($self, $editor, $pos, $line, +1);
	}
	return;
}

sub line_up {
	my ($self, $editor) = @_;

	if ($self->{visual_mode}) {
		$editor->LineUpExtend;
		return;
	}
	#$editor->LineUp; # is this broken?
	my $pos  = $editor->GetCurrentPos;
	my $line = $editor->LineFromPosition($pos);
	if ($line > 1) {
		line_up_down($self, $editor, $pos, $line, -1);
	}
	return;
}

sub line_up_down {
	my ($self, $editor, $pos, $line, $dir) = @_;
		
	my $to;
	my $end      = $editor->GetLineEndPosition($line);
	my $prev_end = $editor->GetLineEndPosition($line + $dir);
	if ($self->{end_pressed}) {
		$to = $prev_end;
	} else {
		my $prev_start = $editor->PositionFromLine($line + $dir);
		my $col  = $editor->GetColumn($pos);
		$to = $prev_start + $col;
		$to = List::Util::min($to, $prev_end);
	}
	$editor->GotoPos($to);
	#$self->visual($editor);
	return;
}



sub goto_end_of_line {
	my ($self, $editor) = @_;
	$self->{end_pressed} = 1;
	if ($self->{visual_mode}) {
		$editor->LineEndExtend();
	} else {
		$editor->LineEnd();
	}
}

sub goto_beginning_of_line {
	my ($self, $editor) = @_;
	$self->{end_pressed} = 0;
	if ($self->{visual_mode}) {
		$editor->HomeExtend;
	} else {
		$editor->Home;
	}
}

sub select_text {
	my ($self, $editor, $count) = @_;
	my $line  = $editor->GetCurrentLine;
	my $start = $editor->PositionFromLine( $line );
	my $end   = $editor->PositionFromLine( $line + $count );
	#my $end   = $editor->GetLineEndPosition($line+$count-1);
	$editor->GotoPos($start);
	$editor->SetTargetStart($start);
	$editor->SetTargetEnd($end);
	$editor->SetSelection($start, $end);
}

1;

# Copyright 2008 Gabor Szabo.
# LICENSE
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl 5 itself.
