package Padre::Plugin::Emacs;

=head1 NAME

Padre::Plugin::Emacs - Emacs keys/mode for Padre

=head1 DESCRIPTION

Once installed and enabled the user is in full vi-emulation mode,
which was partially implemented.

The 3 basic modes of vi are in development:

=cut

use strict;
use warnings;

use base 'Padre::Plugin';

our $VERSION = '0.18';

use List::Util ();

my %subs;
$subs{CTRL} = {
	ord('X') => sub { # ctrl-x ...
		my $self = shift;
		$self->{emacs_ctrl_x_mode} = 1;
	},

	ord('S') => sub { # ctrl-x ctrl-s
		my $self = shift;
		if ($self->{emacs_ctrl_x_mode}) {
			$self->{emacs_ctrl_x_mode} = 0;
			my $main = Padre->ide->wx->main_window;
			$main->on_save;
		}
	},

	
	ord('A') => sub { # ctrl-x ...
		my $self = shift;
		$self->goto_beginning_of_line;	
	},
	ord('E') => sub { # ctrl-x ...
		my $self = shift;
		$self->goto_end_of_line;
	},
	Wx::WXK_SPACE => sub { # ctrl-space
		my $self = shift;
		if ($self->{emacs_select_start_mark}) {
			$self->{emacs_select_end_mark} = $self->GetCurrentPos;
		} else {
			$self->{emacs_select_start_mark} = $self->GetCurrentPos;
		}
	},
	ord('G') => sub { # ctrl-g ... stop
		my $self = shift;
		$self->{emacs_ctrl_x_mode} = 0;
	},
	ord('W') => sub { # ctrl-g ... stop
		my $self = shift;
		my $start_pos = $self->{emacs_select_start_mark};
		my $end_pos = $self->{emacs_select_end_mark} || $self->GetCurrentPos;
		$self->SetTargetStart($start_pos);
	    $self->SetTargetEnd($end_pos);
		$self->SetSelection($start_pos, $end_pos);
		Padre::Wx::Editor::text_cut_to_clipboard();
		$self->{emacs_select_start_mark} = undef;
		$self->{emacs_select_end_mark} = undef;
	},
	ord('K') => sub { # ctrl-g ... stop
		my $self = shift;
		my $start_pos = $self->GetCurrentPos;
		my $line = $self->LineFromPosition($start_pos);
		my $end_pos  = $self->GetLineEndPosition($line);
		$self->SetTargetStart($start_pos);
	    $self->SetTargetEnd($end_pos);
		$self->SetSelection($start_pos, $end_pos);
		Padre::Wx::Editor::text_cut_to_clipboard();
		$self->{emacs_select_start_mark} = undef;
		$self->{emacs_select_end_mark} = undef;
	},
	ord('Y') => sub {
		my $self = shift;
		Padre::Wx::Editor::text_paste_from_clipboard();
		$self->{emacs_select_start_mark} = undef;
		$self->{emacs_select_end_mark} = undef;
	},
};

$subs{META} = {
	ord('W') => sub { # copy
		my $self = shift;
		my $start_pos = $self->{emacs_select_start_mark};
		my $end_pos = $self->{emacs_select_end_mark} || $self->GetCurrentPos;
		$self->SetTargetStart($start_pos);
	    $self->SetTargetEnd($end_pos);
		$self->SetSelection($start_pos, $end_pos);
		Padre::Wx::Editor::text_copy_to_clipboard();
		$self->{emacs_select_start_mark} = undef;
		$self->{emacs_select_end_mark} = undef;
	},
};

$subs{CTRL_SHIFT} = {
		ord('-') => sub { # undo
			my $self = shift;
			$self->CmdKeyExecute(Wx::wxSTC_CMD_UNDO);
		},
		ord('_') => sub { # undo
			my $self = shift;
			$self->CmdKeyExecute(Wx::wxSTC_CMD_UNDO);
		}
};


# http://wxruby.rubyforge.org/doc/acceleratortable.html
# http://www.perl.com/lpt/a/588

# have to create a keyevent object which is called by hotkeys and then handle those events
# how to get keycode and modifier during event?
#					my $mod  = $event->GetModifiers || 0;
#					my $code = $event->GetKeyCode;
# should be a http://www.wxpython.org/docs/api/wx.KeyEvent-class.html key event
# which has GetModifiers and GetKeyCode
# http://osdir.com/ml/lang.perl.wxperl/2005-01/msg00047.html
# http://kobesearch.cpan.org/htdocs/Wx-Perl-TreeChecker/Wx/Perl/TreeChecker.pm.html
# http://wolkendek.nl/wx/bug.pl
# http://markmail.org/message/44t5sk7oosjfxkbr?q=perl+wx+acceleratortable&page=1&refer=x4lo6p7s4krtqpea#query:perl%20wx%20acceleratortable+page:1+mid:7bkbzxzrkewrg2gk+state:results

# set up a new event type
our $ACCEL_KEY_EVENT : shared = Wx::NewEventType();

sub setup_emacs_accelerator_keys_table {
  my $self = shift;
  # Set up the event handler
  my $main = Padre->ide->wx->main_window;
  Wx::Event::EVT_COMMAND($main, -1, $ACCEL_KEY_EVENT, \&on_accel_key_event);

  my $ATable = Wx::AcceleratorTable->new(
					 [wxACCEL_CTRL,ord('X'),$ACCEL_KEY_EVENT],
					);

  my $main_window = Padre->ide->wx->main_window;
  $main_window->SetAcceleratorTable($ATable);
}

sub on_accel_key_event {

  if (my $sub = $subs{$modifier}{$code}) {
    unless (ref $subs{$modifier}{$code} eq 'CODE') {
      warn "Invalid entry in 'subs' hash for code '$code' - expected code ref got : " . ref $subs{$modifier}{$code} ;
      $event->Skip(1);
      return;
    }
    $sub->($self);
  }
}

sub setup_emacs_mode {
	my ($self) = @_;
    $self->CmdKeyClear(ord('w'),Wx::wxMOD_ALT());
    $self->CmdKeyClear(ord('w'),Wx::wxMOD_CMD());
    $self->CmdKeyClear(ord('W'),Wx::wxMOD_ALT());
    $self->CmdKeyClear(ord('W'),Wx::wxMOD_CMD());
    $self->CmdKeyClear(ord('s'),Wx::wxMOD_CMD());
    $self->CmdKeyClear(ord('S'),Wx::wxMOD_CMD());

	$self->CmdKeyClear(Wx::WXK_SPACE,Wx::wxMOD_CMD());

	$self->SetTabIndents(1);

   my $main_window = Padre->ide->wx->main_window;
   my $menu = $main_window->{menu};
    $menu->{win}->CmdKeyClear(ord('w'),Wx::wxMOD_ALT());
    $menu->{win}->CmdKeyClear(ord('w'),Wx::wxMOD_CMD());
    $menu->{win}->CmdKeyClear(ord('W'),Wx::wxMOD_ALT());
    $menu->{win}->CmdKeyClear(ord('W'),Wx::wxMOD_CMD());
    $menu->{win}->CmdKeyClear(ord('s'),Wx::wxMOD_CMD());
    $menu->{win}->CmdKeyClear(ord('S'),Wx::wxMOD_CMD());

	$menu->{win}->CmdKeyClear(Wx::WXK_SPACE,Wx::wxMOD_CMD());
    

   Wx::Event::EVT_KEY_DOWN( $self, sub {
		my ($self, $event) = @_;

		if (not Padre->ide->config->{emacs_mode}) {
			$event->Skip(1);
			return;
		}
		$self->emacs_mode($event);
		return;
	});
	
	Wx::Event::EVT_KEY_UP( $self, sub {
                my ($self, $event) = @_;
                
                unless ( $self->emacs_mode($event) ) {
					$main_window->refresh_status;
					$main_window->refresh_toolbar;
					my $mod  = $event->GetModifiers || 0;
					my $code = $event->GetKeyCode;
                
					# remove the bit ( Wx::wxMOD_META) set by Num Lock being pressed on Linux
					$mod = $mod & (Wx::wxMOD_ALT() + Wx::wxMOD_CMD() + Wx::wxMOD_SHIFT());
					if ( $mod == Wx::wxMOD_CMD ) { # Ctrl
                        # Ctrl-TAB  #TODO it is already in the menu
                        $main_window->on_next_pane if $code == Wx::WXK_TAB;
					} elsif ( $mod == Wx::wxMOD_CMD() + Wx::wxMOD_SHIFT()) { # Ctrl-Shift
                        # Ctrl-Shift-TAB #TODO it is already in the menu
                        $main_window->on_prev_pane if $code == Wx::WXK_TAB;
					}
                }
                return;
    } );


	return;
}

# TODO can we somehow remove the event handler when not needed?
# sub remove_emacs_mode {

		
sub emacs_mode {
	my ($self, $event) = @_;

	my $mod  = $event->GetModifiers || 0;
	my $code = $event->GetKeyCode;

	$event->Skip(0);

	# remove the bit ( Wx::wxMOD_META) set by Num Lock being pressed on Linux
	$mod = $mod & (Wx::wxMOD_ALT() + Wx::wxMOD_CMD() + Wx::wxMOD_SHIFT());
	
	my $modifier;
	$modifier = 'CTRL' if ($mod == Wx::wxMOD_CMD() );
	$modifier = 'CTRL_SHIFT' if ($mod == Wx::wxMOD_CMD() + Wx::wxMOD_SHIFT());
	$modifier = 'META' if ($mod == Wx::wxMOD_ALT() );

    unless ($modifier && $subs{$modifier}) {
    	$event->Skip(1);
		return;
    }

	if (my $sub = $subs{$modifier}{$code}) {
	    unless (ref $subs{$modifier}{$code} eq 'CODE') {
			warn "Invalid entry in 'subs' hash for code '$code' - expected code ref got : " . ref $subs{$modifier}{$code} ;
			$event->Skip(1);
			return;
		}
		$sub->($self);
#		$event->StopPropogation();
		return 1;
	} else {
		$event->Skip(1);
	} 
	
	return;
}

sub goto_end_of_line {
	my $self = shift;
	my $pos  = $self->GetCurrentPos;
	my $line = $self->LineFromPosition($pos);
	my $end  = $self->GetLineEndPosition($line);
	$self->GotoPos($end);
}

sub goto_beginning_of_line {
	my $self = shift;
	$self->Home;
}

1;
