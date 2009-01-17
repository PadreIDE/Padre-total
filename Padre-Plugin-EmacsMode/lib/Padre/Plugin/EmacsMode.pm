package Padre::Plugin::Emacs;

=head1 NAME

Padre::Plugin::Emacs - Emacs keys/mode for Padre

=head1 DESCRIPTION

Once installed and enables provides a subset of emacs
keybindings and commands

=cut

use strict;
use warnings;

use base 'Padre::Plugin';

our $VERSION = '0.18';

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


# The plugin name to show in the Plugins menu
# The command structure to show in the Plugins menu
sub menu_plugins_simple {
  my $self = shift;
  return 'Emacs Mode' => [
			  About => sub { $self->show_about },
			  Commands => [
				       'Emacs Ctrl Command \tCtrl-X' => $subs{CTRL}{ord('X')},
				       'Emacs Meta Command \tAlt-X' => $subs{META}{ord('X')},
				      ]
			 ],
			];
}

sub show_about {
  my ($main) = @_;

  my $about = Wx::AboutDialogInfo->new;
  $about->SetName("Padre::Plugin::EmacsMode");
  $about->SetDescription(
			 "Emacs Keybindings and stuff\n".
			 "Much todo here\n"
			);
  Wx::AboutBox( $about );
  return;
}

sub plugin_enable {
        my ($self) = @_;

	# get menu keys, store them somewhere
	# menuitems with emacs in

	# add event handling

	return;
}

sub plugin_disable {
        my ($self) = @_;

	# return menu keys from where-ever we stored them

	# remove event handling

        return;
}



sub on_accel_key_event {
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

sub setup_emacs_mode {
	my ($self) = @_;
	$self->SetTabIndents(1);
	Wx::Event::EVT_KEY_DOWN( $self, sub {
	    my ($self, $event) = @_;
	    
	    if (not Padre->ide->config->{emacs_mode}) {
		$event->Skip(1);
		return;
	    }
	    $self->emacs_mode($event);
	    return;
	  });

	return;
}

# TODO can we somehow remove the event handler when not needed?
# sub remove_emacs_mode {

		

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
