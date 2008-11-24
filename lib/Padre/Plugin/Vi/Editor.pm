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
		my ($self, $count) = @_;
		$self->{end_pressed} = 0;
		if ($self->{visual_mode}) {
			$self->{editor}->CharRightExtend(); # TODO use $count
		} else {
			my $pos  = $self->{editor}->GetCurrentPos;
			$self->{editor}->GotoPos($pos + $count); 
		}
		$self->{vi_buffer} = '';
	},
	Wx::WXK_RIGHT => ord('L'),
	
	ord('H')      => sub {
		my ($self, $count) = @_;
		$self->{end_pressed} = 0;
		if ($self->{visual_mode}) {
			$self->{editor}->CharLeftExtend; # TODO use $count
		} else {
			my $pos  = $self->{editor}->GetCurrentPos;
			$self->{editor}->GotoPos(List::Util::max($pos - $count, 0)); 
		}
		$self->{vi_buffer} = '';
	},
	Wx::WXK_LEFT  => ord('H'),
	
	ord('K')     => \&line_up,
	Wx::WXK_UP   => ord('K'),
	ord('J')     => \&line_down,
	Wx::WXK_DOWN => ord('J'),
	
	Wx::WXK_PAGEUP => sub {
		my ($self, $count) = @_; # TODO use $count ??
		if ($self->{visual_mode}) {
			$self->{editor}->PageUpExtend;
		} else {
			$self->{editor}->PageUp;
		}
	},
	Wx::WXK_PAGEDOWN => sub {
		my ($self, $count) = @_; # TODO use $count ??
		if ($self->{visual_mode}) {
			$self->{editor}->PageDownExtend;
		} else {
			$self->{editor}->PageDown;
		}
	},
	Wx::WXK_HOME => \&goto_beginning_of_line,
	Wx::WXK_END => \&goto_end_of_line,


	# selection
	ord('V')     => sub {
		my ($self, $count) = @_;
		my $main   = Padre->ide->wx->main_window;
		$self->{editor}->text_selection_mark_start($main);
		$self->{visual_mode} = 1;
	},
	### swictch to insert mode
	ord('A')   => sub {  # append
		my ($self, $count) = @_; # TODO use $count ??
		$self->{vi_insert_mode} = 1;
		# change cursor
	},
	ord('I') => sub { # insert
		my ($self, $count) = @_; # use $count ?
		$self->{vi_insert_mode} = 1;
		my $pos  = $self->{editor}->GetCurrentPos;
		$self->{editor}->GotoPos($pos-1);
		# change cursor
	},
	ord('O') => sub { # open below
		my ($self, $count) = @_; # TODO use $count ??
		$self->{vi_insert_mode} = 1;
		my $line = $self->{editor}->GetCurrentLine;
		my $end  = $self->{editor}->GetLineEndPosition($line);
		# go to end of line, insert newline
		$self->{editor}->GotoPos($end);
		$self->{editor}->NewLine;
		# change cursor
	},
	
	ord('D') => sub {
		my ($self, $count) = @_;
		if ($self->{vi_buffer} =~ /^(\d*)d$/) { # delete current line
			$self->select_text($1 || 1);
			$self->{editor}->Cut;
			# got to first char, remove $count rows
			$self->{vi_buffer} = '';
		} else {
			$self->{vi_buffer} .= 'd';
		}
	},
	
	ord('Y') => sub {
		my ($self, $count) = @_;
		if ($self->{vi_buffer} =~ /^(\d*)y$/) { # yank current line
			$self->select_text($1 || 1);
			$self->{editor}->Copy;

			# got to first char, remove $count rows
			$self->{vi_buffer} = '';
		} else {
			$self->{vi_buffer} .= 'y';
		}
	},

	### editing from navigation mode
	ord('X') => sub { # delete
		my ($self, $count) = @_;
		my $pos  = $self->{editor}->GetCurrentPos;
		$self->{editor}->SetTargetStart($pos);
		$self->{editor}->SetTargetEnd($pos + $count);
		$self->{vi_buffer} = '';
		$self->{editor}->ReplaceTarget('');
	},
	ord('U') => sub { # undo
		my ($self, $count) = @_;
		$self->{editor}->Undo;
	},
	ord('P') => sub { #paste
		my ($self, $count) = @_;
		my $text = Padre::Wx::Editor::get_text_from_clipboard();
		if ($text =~ /\n/) {
			my $line  = $self->{editor}->GetCurrentLine;
			my $start = $self->{editor}->PositionFromLine($line+1);
			$self->{editor}->GotoPos($start);
		}
		$self->{editor}->Paste;
	},
};

$subs{SHIFT} = {
	ord('O') => sub { # open above
		my ($self, $count) = @_;
		$self->{vi_insert_mode} = 1;
		my $line  = $self->{editor}->GetCurrentLine;
		my $start = $self->{editor}->PositionFromLine($line);
		# go to beginning of line, insert newline, go to previous line
		$self->{editor}->GotoPos($start);
		$self->{editor}->NewLine;
		$self->{editor}->GotoPos($start);
		# change cursor
	},
	ord('J') => sub {
		my ($self, $count) = @_;
		my $main   = Padre->ide->wx->main_window;
		$main->on_join_lines;
	},
	ord('P') => sub { #paste above
		my ($self, $count) = @_;
		my $text = Padre::Wx::Editor::get_text_from_clipboard();
		if ($text =~ /\n/) {
			my $line  = $self->{editor}->GetCurrentLine;
			my $start = $self->{editor}->PositionFromLine($line);
			$self->{editor}->GotoPos($start);
		} else {
			my $pos = $self->{editor}->GetCurrentPos;
			$self->{editor}->GotoPos($pos-1);
		}
		$self->{editor}->Paste;
	},
	ord('G') => sub { # goto line
		my ($self, $count) = @_; # TODO: special case for count !!
		$count = $self->{vi_buffer} || $self->{editor}->GetLineCount;
		$self->{editor}->GotoLine($count-1);
		$self->{vi_buffer} = '';
	},
	ord('4') => \&goto_end_of_line, # Shift-4 is $   End
	ord('6') => \&goto_beginning_of_line, # Shift-6 is ^   Home
};

# the following does not yet work as we need to neuralize the Ctrl-N of Padre
# before we can see this command
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
		
		my $count = $self->{vi_buffer} =~ /^(\d+)/ ? $1 : 1; 
		if ($sub) {
			$sub->($self, $count);
		}
		#$self->{vi_buffer} = '';
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
	my ($self) = @_;
	if ($self->{visual_mode}) {
		$self->{editor}->LineDownExtend;
		return;
	}
	#$self->{editor}->LineDown; # is this broken?
	my $pos  = $self->{editor}->GetCurrentPos;
	my $line = $self->{editor}->LineFromPosition($pos);
	my $last_line = $self->{editor}->LineFromPosition(length $self->{editor}->GetText);
	my $count = $self->{vi_buffer} =~ /^\d+$/ ? $self->{vi_buffer} : 1; 
	my $toline = List::Util::min($line+$count, $last_line);
	line_up_down($self, $pos, $line, $toline);
	$self->{vi_buffer} = '';
	return;
}

sub line_up {
	my ($self) = @_;

	if ($self->{visual_mode}) {
		$self->{editor}->LineUpExtend;
		return;
	}
	#$self->{editor}->LineUp; # is this broken?
	my $pos  = $self->{editor}->GetCurrentPos;
	my $line = $self->{editor}->LineFromPosition($pos);
	my $count = $self->{vi_buffer} =~ /^\d+$/ ? $self->{vi_buffer} : 1; 
	my $toline = List::Util::max($line-$count, 0);
	line_up_down($self, $pos, $line, $toline);
	$self->{vi_buffer} = '';
	return;
}

sub line_up_down {
	my ($self, $pos, $line, $toline) = @_;
		
	my $to;
	my $end      = $self->{editor}->GetLineEndPosition($line);
	my $prev_end = $self->{editor}->GetLineEndPosition($toline);
	if ($self->{end_pressed}) {
		$to = $prev_end;
	} else {
		my $prev_start = $self->{editor}->PositionFromLine($toline);
		my $col  = $self->{editor}->GetColumn($pos);
		$to = $prev_start + $col;
		$to = List::Util::min($to, $prev_end);
	}
	$self->{editor}->GotoPos($to);
	return;
}



sub goto_end_of_line {
	my ($self) = @_;
	$self->{end_pressed} = 1;
	if ($self->{visual_mode}) {
		$self->{editor}->LineEndExtend();
	} else {
		$self->{editor}->LineEnd();
	}
}

sub goto_beginning_of_line {
	my ($self) = @_;
	$self->{end_pressed} = 0;
	if ($self->{visual_mode}) {
		$self->{editor}->HomeExtend;
	} else {
		$self->{editor}->Home;
	}
}

sub select_text {
	my ($self, $count) = @_;
	my $line  = $self->{editor}->GetCurrentLine;
	my $start = $self->{editor}->PositionFromLine( $line );
	my $end   = $self->{editor}->PositionFromLine( $line + $count );
	#my $end   = $self->{editor}->GetLineEndPosition($line+$count-1);
	$self->{editor}->GotoPos($start);
	$self->{editor}->SetTargetStart($start);
	$self->{editor}->SetTargetEnd($end);
	$self->{editor}->SetSelection($start, $end);
}

1;

# Copyright 2008 Gabor Szabo.
# LICENSE
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl 5 itself.
