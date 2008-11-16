package Padre::Wx::Editor::Vi;
use strict;
use warnings;

use Padre::Wx::Editor;


package Padre::Wx::Editor;
use strict;
use warnings;

use List::Util ();

sub setup_vi_mode {
	my ($self) = @_;

	$self->{vi_insert_mode} = 0;
	$self->{vi_buffer}      = '';
	Wx::Event::EVT_KEY_DOWN( $self, sub {
		my ($self, $event) = @_;

		if (not Padre->ide->config->{vi_mode}) {
			$event->Skip(1);
			return;
		}
		$self->vi_mode($event);
		return;
	});

	return;
}

# TODO can we somehow remove the event handler when not needed?
# sub remove_vi_mode {

my %subs;

$subs{PLAIN} = {
	ord('L')      => sub {
		my $self = shift;
		$self->{vi_mode_end_pressed} = 0;
		$self->CharRight;
	},
	Wx::WXK_RIGHT => ord('L'),
	
	ord('H')      => sub {
		my $self = shift;
		$self->{vi_mode_end_pressed} = 0;
		$self->CharLeft;
	},
	Wx::WXK_LEFT  => ord('H'),
	
	ord('K')     => \&vi_mode_line_up,
	Wx::WXK_UP   => ord('K'),
	ord('J')     => \&vi_mode_line_down,
	Wx::WXK_DOWN => ord('J'),
	
	Wx::WXK_PAGEUP => sub {
		my $self = shift;
		$self->PageUp;
	},
	Wx::WXK_PAGEDOWN => sub {
		my $self = shift;
		$self->PageDown;
	},
	Wx::WXK_HOME => sub {
		my $self = shift;
		$self->{vi_mode_end_pressed} = 0;
		$self->Home;
	},
	Wx::WXK_END => sub {
		my $self = shift;
		$self->{vi_mode_end_pressed} = 1;
		my $pos  = $self->GetCurrentPos;
		my $line = $self->LineFromPosition($pos);
		my $end  = $self->GetLineEndPosition($line);
		$self->GotoPos($end);
	},
	

	### swictch to insert mode
	ord('A')   => sub {  # append
		my $self = shift;
		$self->{vi_insert_mode} = 1;
		# change cursor
	},
	ord('I') => sub { # insert
		my $self = shift;
		$self->{vi_insert_mode} = 1;
		my $pos  = $self->GetCurrentPos;
		$self->GotoPos($pos-1);
		# change cursor
	},
	ord('O') => sub { # open below
		my $self = shift;
		$self->{vi_insert_mode} = 1;
		my $line = $self->GetCurrentLine;
		my $end = $self->GetLineEndPosition($line);
		# go to end of line, insert newline
		$self->GotoPos($end);
		$self->NewLine;
		# change cursor
	},
	
	ord('D') => sub {
		my $self = shift;
		if ($self->{vi_buffer} =~ /^(\d*)d$/) { # delete current line
			my $count = $1 || 1;
			my $line = $self->GetCurrentLine;
			my $start = $self->PositionFromLine( $line );
			my $end   = $self->PositionFromLine( $line + $count );
			#my $end   = $self->GetLineEndPosition($line+$count-1);
			$self->GotoPos($start);
			$self->SetTargetStart($start);
			$self->SetTargetEnd($end);
			$self->SetSelection($start, $end);

			Padre::Wx::Editor::text_cut_to_clipboard();
			# got to first char, remove $count rows
			$self->{vi_buffer} = '';
		} else {
			$self->{vi_buffer} .= 'd';
		}
	},
	### editing from navigation mode
	ord('X') => sub { # delete
		my $self = shift;
		my $pos  = $self->GetCurrentPos;
		$self->SetTargetStart($pos);
		my $count = $self->{vi_buffer} || 1;
		$self->SetTargetEnd($pos + $count);
		$self->{vi_buffer} = '';
		$self->ReplaceTarget('');
	},
	ord('U') => sub { # undo
		$_[0]->Undo;
	},
};

$subs{SHIFT} = {
	ord('O') => sub { # open above
		my $self = shift;
		$self->{vi_insert_mode} = 1;
		my $line = $self->GetCurrentLine;
		my $start = $self->PositionFromLine($line);
		# go to beginning of line, insert newline, go to previous line
		$self->GotoPos($start);
		$self->NewLine;
		$self->GotoPos($start);
		# change cursor
	},
};

sub vi_mode_line_down {
	my $self = shift;
	#$self->LineDown; # is this broken?
	my $pos  = $self->GetCurrentPos;
	my $line = $self->LineFromPosition($pos);
	my $last_line = $self->LineFromPosition(length $self->GetText);
	if ($line < $last_line) {
		vi_mode_line_up_down($self, $pos, $line, +1);
	}
	return;
}

sub vi_mode_line_up {
	my $self = shift;
	#$self->LineUp; # is this broken?
	my $pos  = $self->GetCurrentPos;
	my $line = $self->LineFromPosition($pos);
	if ($line > 1) {
		vi_mode_line_up_down($self, $pos, $line, -1);
	}
	return;
}

sub vi_mode_line_up_down {
	my ($self, $pos, $line, $dir) = @_;
		
	my $to;
	my $end      = $self->GetLineEndPosition($line);
	my $prev_end = $self->GetLineEndPosition($line + $dir);
	if ($self->{vi_mode_end_pressed}) {
		$to = $prev_end;
	} else {
		my $prev_start = $self->PositionFromLine($line + $dir);
		my $col  = $self->GetColumn($pos);
		$to = $prev_start + $col;
		$to = List::Util::min($to, $prev_end);
	}
	$self->GotoPos($to);
	return;
}


sub vi_mode {
	my ($self, $event) = @_;

	my $mod  = $event->GetModifiers || 0;
	my $code = $event->GetKeyCode;

	if ($code == Wx::WXK_ESCAPE) {
		$self->{vi_insert_mode} = 0;
		$event->Skip(0);
		return;
	}

	if ($self->{vi_insert_mode}) {
		$event->Skip(1);
		return;
	}

# list of keys we don't want to implement but pass back to the STC to handle
#	my %skip = map { $_ => 1 }
#		(Wx::WXK_PAGEDOWN, Wx::WXK_HOME);
#	
#	if ($skip{$code}) {
#		$event->Skip(1);
#		return;
#	}
#
	$event->Skip(0);
	
	if ($code == ord(';') and $mod & 4) { # shift-; also know as :
		Padre::Wx::Dialog::CommandLine->show_prompt();
		return;
	}

	my $modifier = $mod & 4 ? 'SHIFT' : 'PLAIN';

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
			$sub->($self);
		}
		return;
	}

	if (ord('0') <= $code and $code <= ord('9')) {
		$self->{vi_buffer} .= chr($code);
		return;
	}
	
	# left here to easily find extra keys we still need to implement:
	printf("k '%s' '%s', '%s'\n", $mod, $code, 
		(0 < $code and $code < 128 ? chr($code) : ''));
	return;
}

1;
