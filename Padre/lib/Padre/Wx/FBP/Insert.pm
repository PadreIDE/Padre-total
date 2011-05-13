package Padre::Wx::FBP::Insert;

# This module was generated by Padre::Plugin::FormBuilder::Perl.
# To change this module, edit the original .fbp file and regenerate.
# DO NOT MODIFY BY HAND!

use 5.008;
use strict;
use warnings;
use Padre::Wx ();
use Padre::Wx::Role::Main ();

our $VERSION = '0.85';
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
		Wx::gettext("Insert Snippit"),
		Wx::wxDefaultPosition,
		Wx::wxDefaultSize,
		Wx::wxDEFAULT_DIALOG_STYLE,
	);

	my $filter_label = Wx::StaticText->new(
		$self,
		-1,
		Wx::gettext("Filter:"),
	);

	my $filter = Wx::Choice->new(
		$self,
		-1,
		Wx::wxDefaultPosition,
		Wx::wxDefaultSize,
		[],
	);
	$filter->SetSelection(0);

	my $name_label = Wx::StaticText->new(
		$self,
		-1,
		Wx::gettext("Snippit:"),
	);

	my $name = Wx::ComboBox->new(
		$self,
		-1,
		"",
		Wx::wxDefaultPosition,
		Wx::wxDefaultSize,
		[],
	);

	my $m_staticline4 = Wx::StaticLine->new(
		$self,
		-1,
		Wx::wxDefaultPosition,
		Wx::wxDefaultSize,
		Wx::wxLI_HORIZONTAL,
	);

	my $m_staticText11 = Wx::StaticText->new(
		$self,
		-1,
		Wx::gettext("Preview:"),
	);

	my $preview = Wx::TextCtrl->new(
		$self,
		-1,
		"",
		Wx::wxDefaultPosition,
		[ 300, 200 ],
		Wx::wxTE_MULTILINE,
	);

	my $m_staticline1 = Wx::StaticLine->new(
		$self,
		-1,
		Wx::wxDefaultPosition,
		Wx::wxDefaultSize,
		Wx::wxLI_HORIZONTAL,
	);

	my $insert = Wx::Button->new(
		$self,
		-1,
		Wx::gettext("Insert"),
	);
	$insert->SetDefault;

	my $cancel = Wx::Button->new(
		$self,
		Wx::wxID_CANCEL,
		Wx::gettext("Cancel"),
	);

	my $fgSizer2 = Wx::FlexGridSizer->new( 2, 2, 0, 10 );
	$fgSizer2->AddGrowableCol(1);
	$fgSizer2->SetFlexibleDirection(Wx::wxBOTH);
	$fgSizer2->SetNonFlexibleGrowMode(Wx::wxFLEX_GROWMODE_SPECIFIED);
	$fgSizer2->Add( $filter_label, 0, Wx::wxALIGN_CENTER_VERTICAL | Wx::wxALL, 5 );
	$fgSizer2->Add( $filter, 0, Wx::wxALL | Wx::wxEXPAND, 5 );
	$fgSizer2->Add( $name_label, 0, Wx::wxALIGN_CENTER_VERTICAL | Wx::wxALL, 5 );
	$fgSizer2->Add( $name, 0, Wx::wxALL | Wx::wxEXPAND, 5 );

	my $buttons = Wx::BoxSizer->new(Wx::wxHORIZONTAL);
	$buttons->Add( $insert, 0, Wx::wxALL, 5 );
	$buttons->Add( 0, 0, 1, Wx::wxEXPAND, 5 );
	$buttons->Add( $cancel, 0, Wx::wxALL, 5 );

	my $vsizer = Wx::BoxSizer->new(Wx::wxVERTICAL);
	$vsizer->Add( $fgSizer2, 1, Wx::wxEXPAND, 5 );
	$vsizer->Add( $m_staticline4, 0, Wx::wxEXPAND | Wx::wxALL, 5 );
	$vsizer->Add( $m_staticText11, 0, Wx::wxLEFT | Wx::wxTOP, 5 );
	$vsizer->Add( $preview, 0, Wx::wxALL | Wx::wxEXPAND, 5 );
	$vsizer->Add( $m_staticline1, 0, Wx::wxALL | Wx::wxEXPAND, 5 );
	$vsizer->Add( $buttons, 0, Wx::wxEXPAND, 5 );

	my $sizer = Wx::BoxSizer->new(Wx::wxHORIZONTAL);
	$sizer->Add( $vsizer, 1, Wx::wxALL | Wx::wxEXPAND, 5 );

	$self->SetSizer($sizer);
	$self->Layout;
	$sizer->Fit($self);

	$self->{filter} = $filter->GetId;
	$self->{name} = $name->GetId;
	$self->{preview} = $preview->GetId;

	return $self;
}

sub filter {
	Wx::Window::FindWindowById($_[0]->{filter});
}

sub name {
	Wx::Window::FindWindowById($_[0]->{name});
}

sub preview {
	Wx::Window::FindWindowById($_[0]->{preview});
}

1;

# Copyright 2008-2011 The Padre development team as listed in Padre.pm.
# LICENSE
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl 5 itself.

