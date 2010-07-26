package Padre::Plugin::Emacs;

=head1 NAME

Padre::Plugin::Emacs - Emacs keys/mode for Padre

=head1 DESCRIPTION

Once installed and enables provides a subset of emacs
keybindings and commands

=cut

use strict;
use warnings;

our $VERSION = '0.02';

use Padre::Util;

use base 'Padre::Plugin';

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
			my $main = Padre->ide->wx->main;
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

sub padre_interfaces {
	'Padre::Plugin'   => 0.43,
	'Padre::Document' => 0.43,
}

sub plugin_name {
  return Wx::gettext('Emacs Mode for Padre');
}


# The command structure to show in the Plugins menu
sub menu_plugins_simple {
  my $self = shift;
  return Wx::gettext('Emacs Mode') => [
			  About => sub { $self->show_about },
			  Commands => [
				       'Emacs Ctrl Command \tCtrl-X' => $subs{CTRL}{ord('X')},
				       'Emacs Meta Command \tAlt-X' => $subs{META}{ord('X')},
				      ]
			 ];
}

sub show_about {
  my ($main) = @_;

  my $about = Wx::AboutDialogInfo->new;
  $about->SetName("Padre::Plugin::Emacs");
  $about->SetDescription(
			 "Emacs Keybindings and stuff\n".
			 "Much TODO here\n"
			);
  $about->SetVersion($Padre::Plugin::Emacs::VERSION);
  $about->SetCopyright(Wx::gettext("Copyright 2009 Aaron Trevena"));

  # Only Unix/GTK native about box supports websites
  if ( Padre::Util::WXGTK() ) {
    $about->SetWebSite("http://padre.perlide.org/");
  }

  $about->AddDeveloper("Aaron Trevena : teejay at cpan dot org");

  Wx::AboutBox( $about );
  return;
}

sub plugin_enable {
  my ($self) = @_;

  # behaviour rules (more to come)
  # $self->SetTabIndents(1);

  # get menu keys (FIXME:store them somewhere)
  # skip menuitems with emacs in
  foreach my $mod ( keys %subs ) {
    foreach my $key (keys %{$subs{$mod}}) {
      # check main menubar accel list
      # update menuitems using/clashing
      my $main = Padre::Current->main;
      my $menuitem = $main->{accel_keys}{hotkeys}{$mod}{$key};
      (my $new_label = $menuitem->GetText =~ s/[\_\&]\w//g);
      $menuitem->SetText($new_label); # SetAccel(undef);
    }
  }

  # add event handling
  Wx::Event::EVT_KEY_DOWN( $self, sub {
			     my ($self, $event) = @_;
			     $self->on_accel_key_event($event);
			     return;
			   });

  return;
}

sub plugin_disable {
        my ($self) = @_;

	# return menu keys from where-ever we stored them
	warn "we should undo menu changes we made!!!\n";
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
