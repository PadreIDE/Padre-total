package Padre::Wx::FBP::Snippet;

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

our $VERSION = '1.01';
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
		Wx::gettext("Insert Snippet"),
		Wx::DefaultPosition,
		Wx::DefaultSize,
		Wx::DEFAULT_DIALOG_STYLE,
	);

	my $filter_label = Wx::StaticText->new(
		$self,
		-1,
		Wx::gettext("Filter:"),
	);

	$self->{filter} = Wx::Choice->new(
		$self,
		-1,
		Wx::DefaultPosition,
		Wx::DefaultSize,
		[],
	);
	$self->{filter}->SetSelection(0);

	Wx::Event::EVT_CHOICE(
		$self,
		$self->{filter},
		sub {
			shift->refilter(@_);
		},
	);

	my $name_label = Wx::StaticText->new(
		$self,
		-1,
		Wx::gettext("Snippet:"),
	);

	$self->{select} = Wx::Choice->new(
		$self,
		-1,
		Wx::DefaultPosition,
		Wx::DefaultSize,
		[],
	);
	$self->{select}->SetSelection(0);

	Wx::Event::EVT_CHOICE(
		$self,
		$self->{select},
		sub {
			shift->refresh(@_);
		},
	);

	my $m_staticline4 = Wx::StaticLine->new(
		$self,
		-1,
		Wx::DefaultPosition,
		Wx::DefaultSize,
		Wx::LI_HORIZONTAL,
	);

	my $m_staticText11 = Wx::StaticText->new(
		$self,
		-1,
		Wx::gettext("Preview:"),
	);

	$self->{preview} = Wx::TextCtrl->new(
		$self,
		-1,
		"",
		Wx::DefaultPosition,
		[ 300, 200 ],
		Wx::TE_MULTILINE | Wx::TE_READONLY,
	);
	$self->{preview}->SetBackgroundColour(
		Wx::SystemSettings::GetColour( Wx::SYS_COLOUR_MENU )
	);

	my $m_staticline1 = Wx::StaticLine->new(
		$self,
		-1,
		Wx::DefaultPosition,
		Wx::DefaultSize,
		Wx::LI_HORIZONTAL,
	);

	$self->{insert} = Wx::Button->new(
		$self,
		-1,
		Wx::gettext("Insert"),
		Wx::DefaultPosition,
		Wx::DefaultSize,
	);
	$self->{insert}->SetDefault;

	Wx::Event::EVT_BUTTON(
		$self,
		$self->{insert},
		sub {
			shift->insert_snippet(@_);
		},
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
	$fgSizer2->SetFlexibleDirection(Wx::BOTH);
	$fgSizer2->SetNonFlexibleGrowMode(Wx::FLEX_GROWMODE_SPECIFIED);
	$fgSizer2->Add( $filter_label, 0, Wx::ALIGN_CENTER_VERTICAL | Wx::ALL, 5 );
	$fgSizer2->Add( $self->{filter}, 0, Wx::ALL | Wx::EXPAND, 5 );
	$fgSizer2->Add( $name_label, 0, Wx::ALIGN_CENTER_VERTICAL | Wx::ALL, 5 );
	$fgSizer2->Add( $self->{select}, 0, Wx::ALL | Wx::EXPAND, 5 );

	my $buttons = Wx::BoxSizer->new(Wx::HORIZONTAL);
	$buttons->Add( $self->{insert}, 0, Wx::ALL, 5 );
	$buttons->Add( 0, 0, 1, Wx::EXPAND, 5 );
	$buttons->Add( $self->{cancel}, 0, Wx::ALL, 5 );

	my $vsizer = Wx::BoxSizer->new(Wx::VERTICAL);
	$vsizer->Add( $fgSizer2, 1, Wx::EXPAND, 5 );
	$vsizer->Add( $m_staticline4, 0, Wx::EXPAND | Wx::ALL, 5 );
	$vsizer->Add( $m_staticText11, 0, Wx::LEFT | Wx::TOP, 5 );
	$vsizer->Add( $self->{preview}, 0, Wx::ALL | Wx::EXPAND, 5 );
	$vsizer->Add( $m_staticline1, 0, Wx::ALL | Wx::EXPAND, 5 );
	$vsizer->Add( $buttons, 0, Wx::EXPAND, 5 );

	my $sizer = Wx::BoxSizer->new(Wx::HORIZONTAL);
	$sizer->Add( $vsizer, 1, Wx::ALL | Wx::EXPAND, 5 );

	$self->SetSizerAndFit($sizer);
	$self->Layout;

	return $self;
}

sub filter {
	$_[0]->{filter};
}

sub select {
	$_[0]->{select};
}

sub preview {
	$_[0]->{preview};
}

sub insert {
	$_[0]->{insert};
}

sub cancel {
	$_[0]->{cancel};
}

sub refilter {
	$_[0]->main->error('Handler method refilter for event filter.OnChoice not implemented');
}

sub refresh {
	$_[0]->main->error('Handler method refresh for event select.OnChoice not implemented');
}

sub insert_snippet {
	$_[0]->main->error('Handler method insert_snippet for event insert.OnButtonClick not implemented');
}

1;

# Copyright 2008-2013 The Padre development team as listed in Padre.pm.
# LICENSE
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl 5 itself.

