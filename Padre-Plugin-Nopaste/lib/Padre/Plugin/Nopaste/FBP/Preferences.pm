package Padre::Plugin::Nopaste::FBP::Preferences;

## no critic

# This module was generated by Padre::Plugin::FormBuilder::Perl.
# To change this module edit the original .fbp file and regenerate.
# DO NOT MODIFY THIS FILE BY HAND!

use 5.008005;
use utf8;
use strict;
use warnings;
use Padre::Wx ();
use Padre::Wx::Role::Main ();

our $VERSION = '0.07';
our @ISA     = qw{
	Padre::Wx::Role::Main
	Wx::Dialog
};

sub new {
	my $class  = shift;
	my $parent = shift;

	my $self = $class->SUPER::new(
		$parent,
		-1,
		Wx::gettext("nopaste preferences"),
		Wx::DefaultPosition,
		Wx::DefaultSize,
		Wx::DEFAULT_DIALOG_STYLE | Wx::RESIZE_BORDER,
	);

	$self->{m_static_nickname} = Wx::StaticText->new(
		$self,
		-1,
		Wx::gettext("Nick Name:"),
	);

	$self->{config_nickname} = Wx::StaticText->new(
		$self,
		-1,
		Wx::gettext("config_nickname"),
	);

	$self->{m_static_server} = Wx::StaticText->new(
		$self,
		-1,
		Wx::gettext("Nopaste Server:"),
	);

	$self->{nopaste_server} = Wx::Choice->new(
		$self,
		-1,
		Wx::DefaultPosition,
		[ 220, -1 ],
		[],
	);
	$self->{nopaste_server}->SetSelection(0);

	Wx::Event::EVT_CHOICE(
		$self,
		$self->{nopaste_server},
		sub {
			shift->on_server_chosen(@_);
		},
	);

	$self->{m_static_channel} = Wx::StaticText->new(
		$self,
		-1,
		Wx::gettext("Nopaste Channel:"),
	);

	$self->{nopaste_channel} = Wx::Choice->new(
		$self,
		-1,
		Wx::DefaultPosition,
		[ 220, -1 ],
		[],
	);
	$self->{nopaste_channel}->SetSelection(0);

	$self->{m_staticline1} = Wx::StaticLine->new(
		$self,
		-1,
		Wx::DefaultPosition,
		Wx::DefaultSize,
		Wx::LI_HORIZONTAL,
	);

	$self->{m_button_reset} = Wx::Button->new(
		$self,
		-1,
		Wx::gettext("Reset"),
		Wx::DefaultPosition,
		Wx::DefaultSize,
	);

	Wx::Event::EVT_BUTTON(
		$self,
		$self->{m_button_reset},
		sub {
			shift->on_button_reset_clicked(@_);
		},
	);

	$self->{m_button_cancel} = Wx::Button->new(
		$self,
		Wx::ID_CANCEL,
		Wx::gettext("Cancel"),
		Wx::DefaultPosition,
		Wx::DefaultSize,
	);
	$self->{m_button_cancel}->SetDefault;

	$self->{m_button_save} = Wx::Button->new(
		$self,
		-1,
		Wx::gettext("Save"),
		Wx::DefaultPosition,
		Wx::DefaultSize,
	);
	Wx::Event::EVT_BUTTON(

		$self,
		$self->{m_button_save},
		sub {
			shift->on_button_save_clicked(@_);
		},
	);

	my $gSizer1 = Wx::GridSizer->new( 3, 2, 0, 0 );
	$gSizer1->Add( $self->{m_static_nickname}, 0, Wx::ALL, 5 );
	$gSizer1->Add( $self->{config_nickname}, 0, Wx::ALL, 5 );
	$gSizer1->Add( $self->{m_static_server}, 0, Wx::ALL, 5 );
	$gSizer1->Add( $self->{nopaste_server}, 0, Wx::ALL, 5 );
	$gSizer1->Add( $self->{m_static_channel}, 0, Wx::ALL, 5 );
	$gSizer1->Add( $self->{nopaste_channel}, 0, Wx::ALL, 5 );

	my $bSizer2 = Wx::BoxSizer->new(Wx::HORIZONTAL);
	$bSizer2->Add( $self->{m_button_reset}, 0, Wx::ALL, 5 );
	$bSizer2->Add( 0, 0, 1, Wx::EXPAND, 5 );
	$bSizer2->Add( $self->{m_button_cancel}, 0, Wx::ALL, 5 );
	$bSizer2->Add( $self->{m_button_save}, 0, Wx::ALL, 5 );

	my $bSizer1 = Wx::BoxSizer->new(Wx::VERTICAL);
	$bSizer1->Add( $gSizer1, 0, Wx::ALL | Wx::EXPAND, 5 );
	$bSizer1->Add( $self->{m_staticline1}, 0, Wx::EXPAND | Wx::ALL, 5 );
	$bSizer1->Add( $bSizer2, 0, Wx::EXPAND, 5 );

	$self->SetSizerAndFit($bSizer1);
	$self->Layout;

	return $self;
}

sub config_nickname {
	$_[0]->{config_nickname};
}

sub nopaste_server {
	$_[0]->{nopaste_server};
}

sub nopaste_channel {
	$_[0]->{nopaste_channel};
}

sub on_server_chosen {
	$_[0]->main->error('Handler method on_server_chosen for event nopaste_server.OnChoice not implemented');
}

sub on_button_reset_clicked {
	$_[0]->main->error('Handler method on_button_reset_clicked for event m_button_reset.OnButtonClick not implemented');
}

sub on_button_save_clicked {
	$_[0]->main->error('Handler method on_button_save_clicked for event m_button_save.OnButtonClick not implemented');
}

1;

# Copyright 2008-2012 The Padre development team as listed in Padre.pm.
# LICENSE
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl 5 itself.

