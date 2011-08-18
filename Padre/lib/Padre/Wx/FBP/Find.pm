package Padre::Wx::FBP::Find;

## no critic

# This module was generated by Padre::Plugin::FormBuilder::Perl.
# To change this module edit the original .fbp file and regenerate.
# DO NOT MODIFY THIS FILE BY HAND!

use 5.008;
use strict;
use warnings;
use Padre::Wx ();
use Padre::Wx::Role::Main ();
use Padre::Wx::History::ComboBox ();

our $VERSION = '0.91';
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
		Wx::gettext("Find"),
		Wx::DefaultPosition,
		Wx::DefaultSize,
		Wx::wxDEFAULT_DIALOG_STYLE,
	);

	my $m_staticText2 = Wx::StaticText->new(
		$self,
		-1,
		Wx::gettext("Search &Term") . ":",
	);

	$self->{find_term} = Padre::Wx::History::ComboBox->new(
		$self,
		-1,
		"",
		Wx::DefaultPosition,
		Wx::DefaultSize,
		[
			"search",
		],
	);

	Wx::Event::EVT_TEXT(
		$self,
		$self->{find_term},
		sub {
			shift->refresh(@_);
		},
	);

	my $m_staticline2 = Wx::StaticLine->new(
		$self,
		-1,
		Wx::DefaultPosition,
		Wx::DefaultSize,
		Wx::wxLI_HORIZONTAL,
	);

	$self->{find_regex} = Wx::CheckBox->new(
		$self,
		-1,
		Wx::gettext("&Regular Expression"),
		Wx::DefaultPosition,
		Wx::DefaultSize,
	);

	$self->{find_reverse} = Wx::CheckBox->new(
		$self,
		-1,
		Wx::gettext("Search &Backwards"),
		Wx::DefaultPosition,
		Wx::DefaultSize,
	);

	$self->{find_case} = Wx::CheckBox->new(
		$self,
		-1,
		Wx::gettext("&Case Sensitive"),
		Wx::DefaultPosition,
		Wx::DefaultSize,
	);

	$self->{find_first} = Wx::CheckBox->new(
		$self,
		-1,
		Wx::gettext("Cl&ose Window on Hit"),
		Wx::DefaultPosition,
		Wx::DefaultSize,
	);

	my $m_staticline1 = Wx::StaticLine->new(
		$self,
		-1,
		Wx::DefaultPosition,
		Wx::DefaultSize,
		Wx::wxLI_HORIZONTAL,
	);

	$self->{find_next} = Wx::Button->new(
		$self,
		Wx::ID_OK,
		Wx::gettext("Find &Next"),
		Wx::DefaultPosition,
		Wx::DefaultSize,
	);
	$self->{find_next}->SetDefault;

	Wx::Event::EVT_BUTTON(
		$self,
		$self->{find_next},
		sub {
			shift->find_next_clicked(@_);
		},
	);

	$self->{find_all} = Wx::Button->new(
		$self,
		Wx::ID_OK,
		Wx::gettext("Find &All"),
		Wx::DefaultPosition,
		Wx::DefaultSize,
	);

	$self->{cancel} = Wx::Button->new(
		$self,
		Wx::ID_CANCEL,
		Wx::gettext("Cancel"),
		Wx::DefaultPosition,
		Wx::DefaultSize,
	);

	my $fgSizer2 = Wx::FlexGridSizer->new( 2, 2, 0, 10 );
	$fgSizer2->AddGrowableCol(1);
	$fgSizer2->SetFlexibleDirection(Wx::wxBOTH);
	$fgSizer2->SetNonFlexibleGrowMode(Wx::wxFLEX_GROWMODE_SPECIFIED);
	$fgSizer2->Add( $self->{find_regex}, 1, Wx::wxALL, 5 );
	$fgSizer2->Add( $self->{find_reverse}, 1, Wx::wxALL, 5 );
	$fgSizer2->Add( $self->{find_case}, 1, Wx::wxALL, 5 );
	$fgSizer2->Add( $self->{find_first}, 1, Wx::wxALL, 5 );

	my $buttons = Wx::BoxSizer->new(Wx::wxHORIZONTAL);
	$buttons->Add( $self->{find_next}, 0, Wx::wxALL, 5 );
	$buttons->Add( $self->{find_all}, 0, Wx::wxALL, 5 );
	$buttons->Add( 20, 0, 1, Wx::wxEXPAND, 5 );
	$buttons->Add( $self->{cancel}, 0, Wx::wxALL, 5 );

	my $vsizer = Wx::BoxSizer->new(Wx::wxVERTICAL);
	$vsizer->Add( $m_staticText2, 0, Wx::wxALIGN_CENTER_VERTICAL | Wx::wxLEFT | Wx::wxRIGHT | Wx::wxTOP, 5 );
	$vsizer->Add( $self->{find_term}, 0, Wx::wxALIGN_CENTER_VERTICAL | Wx::wxALL | Wx::wxEXPAND, 5 );
	$vsizer->Add( $m_staticline2, 0, Wx::wxALL | Wx::wxEXPAND, 5 );
	$vsizer->Add( $fgSizer2, 1, Wx::wxBOTTOM | Wx::wxEXPAND, 5 );
	$vsizer->Add( $m_staticline1, 0, Wx::wxALL | Wx::wxEXPAND, 5 );
	$vsizer->Add( $buttons, 0, Wx::wxEXPAND, 5 );

	my $hsizer = Wx::BoxSizer->new(Wx::wxHORIZONTAL);
	$hsizer->Add( $vsizer, 1, Wx::wxALL | Wx::wxEXPAND, 5 );

	$self->SetSizerAndFit($hsizer);
	$self->Layout;

	return $self;
}

sub find_term {
	$_[0]->{find_term};
}

sub find_regex {
	$_[0]->{find_regex};
}

sub find_reverse {
	$_[0]->{find_reverse};
}

sub find_case {
	$_[0]->{find_case};
}

sub find_first {
	$_[0]->{find_first};
}

sub find_next {
	$_[0]->{find_next};
}

sub find_all {
	$_[0]->{find_all};
}

sub refresh {
	$_[0]->main->error('Handler method refresh for event find_term.OnText not implemented');
}

sub find_next_clicked {
	$_[0]->main->error('Handler method find_next_clicked for event find_next.OnButtonClick not implemented');
}

1;

# Copyright 2008-2011 The Padre development team as listed in Padre.pm.
# LICENSE
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl 5 itself.

