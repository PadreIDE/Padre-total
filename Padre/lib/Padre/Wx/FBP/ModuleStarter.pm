package Padre::Wx::FBP::ModuleStarter;

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

our $VERSION = '0.97';
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
		Wx::gettext("Module Starter"),
		Wx::DefaultPosition,
		Wx::DefaultSize,
		Wx::DEFAULT_DIALOG_STYLE,
	);

	$self->{m_staticText4} = Wx::StaticText->new(
		$self,
		-1,
		Wx::gettext("Module Name:"),
	);

	$self->{module} = Wx::TextCtrl->new(
		$self,
		-1,
		"",
		Wx::DefaultPosition,
		Wx::DefaultSize,
	);
	$self->{module}->SetMinSize( [ 280, -1 ] );
	$self->{module}->SetToolTip(
		Wx::gettext("You can now add multiple module names, ie: Foo::Bar, Foo::Bar::Two (csv)")
	);

	$self->{m_staticText8} = Wx::StaticText->new(
		$self,
		-1,
		Wx::gettext("Author:"),
	);

	$self->{identity_name} = Wx::TextCtrl->new(
		$self,
		-1,
		"",
		Wx::DefaultPosition,
		Wx::DefaultSize,
	);

	$self->{m_staticText5} = Wx::StaticText->new(
		$self,
		-1,
		Wx::gettext("Email Address:"),
	);

	$self->{identity_email} = Wx::TextCtrl->new(
		$self,
		-1,
		"",
		Wx::DefaultPosition,
		Wx::DefaultSize,
	);

	my $m_staticText6 = Wx::StaticText->new(
		$self,
		-1,
		Wx::gettext("Builder:"),
	);

	$self->{module_starter_builder} = Wx::Choice->new(
		$self,
		-1,
		Wx::DefaultPosition,
		Wx::DefaultSize,
		[],
	);
	$self->{module_starter_builder}->SetSelection(0);

	$self->{m_staticText7} = Wx::StaticText->new(
		$self,
		-1,
		Wx::gettext("License:"),
	);

	$self->{module_starter_license} = Wx::Choice->new(
		$self,
		-1,
		Wx::DefaultPosition,
		Wx::DefaultSize,
		[],
	);
	$self->{module_starter_license}->SetSelection(0);

	$self->{m_staticText3} = Wx::StaticText->new(
		$self,
		-1,
		Wx::gettext("Parent Directory:"),
	);

	$self->{module_starter_directory} = Wx::DirPickerCtrl->new(
		$self,
		-1,
		"",
		Wx::gettext("Select a folder"),
		Wx::DefaultPosition,
		Wx::DefaultSize,
		Wx::DIRP_DEFAULT_STYLE,
	);

	my $m_staticline1 = Wx::StaticLine->new(
		$self,
		-1,
		Wx::DefaultPosition,
		Wx::DefaultSize,
		Wx::LI_HORIZONTAL,
	);

	my $ok = Wx::Button->new(
		$self,
		Wx::ID_OK,
		Wx::gettext("OK"),
		Wx::DefaultPosition,
		Wx::DefaultSize,
	);
	$ok->SetDefault;

	Wx::Event::EVT_BUTTON(
		$self,
		$ok,
		sub {
			shift->ok_clicked(@_);
		},
	);

	my $cancel = Wx::Button->new(
		$self,
		Wx::ID_CANCEL,
		Wx::gettext("Cancel"),
		Wx::DefaultPosition,
		Wx::DefaultSize,
	);

	my $fgSizer1 = Wx::FlexGridSizer->new( 2, 2, 0, 10 );
	$fgSizer1->AddGrowableCol(1);
	$fgSizer1->SetFlexibleDirection(Wx::BOTH);
	$fgSizer1->SetNonFlexibleGrowMode(Wx::FLEX_GROWMODE_SPECIFIED);
	$fgSizer1->Add( $self->{m_staticText4}, 0, Wx::ALIGN_CENTER_VERTICAL | Wx::ALL, 5 );
	$fgSizer1->Add( $self->{module}, 0, Wx::ALL | Wx::EXPAND, 5 );
	$fgSizer1->Add( $self->{m_staticText8}, 0, Wx::ALIGN_CENTER_VERTICAL | Wx::ALL, 5 );
	$fgSizer1->Add( $self->{identity_name}, 0, Wx::ALL | Wx::EXPAND, 5 );
	$fgSizer1->Add( $self->{m_staticText5}, 0, Wx::ALIGN_CENTER_VERTICAL | Wx::ALL, 5 );
	$fgSizer1->Add( $self->{identity_email}, 0, Wx::ALL | Wx::EXPAND, 5 );
	$fgSizer1->Add( $m_staticText6, 0, Wx::ALIGN_CENTER_VERTICAL | Wx::ALL, 5 );
	$fgSizer1->Add( $self->{module_starter_builder}, 0, Wx::ALL | Wx::EXPAND, 5 );
	$fgSizer1->Add( $self->{m_staticText7}, 0, Wx::ALIGN_CENTER_VERTICAL | Wx::ALL, 5 );
	$fgSizer1->Add( $self->{module_starter_license}, 0, Wx::ALL | Wx::EXPAND, 5 );
	$fgSizer1->Add( $self->{m_staticText3}, 0, Wx::ALL, 5 );
	$fgSizer1->Add( $self->{module_starter_directory}, 0, Wx::ALL | Wx::EXPAND, 5 );

	my $buttons = Wx::BoxSizer->new(Wx::HORIZONTAL);
	$buttons->Add( $ok, 0, Wx::ALL, 5 );
	$buttons->Add( 100, 0, 1, Wx::EXPAND, 5 );
	$buttons->Add( $cancel, 0, Wx::ALL, 5 );

	my $vsizer = Wx::BoxSizer->new(Wx::VERTICAL);
	$vsizer->Add( $fgSizer1, 1, Wx::EXPAND, 5 );
	$vsizer->Add( $m_staticline1, 0, Wx::ALL | Wx::EXPAND, 5 );
	$vsizer->Add( $buttons, 0, Wx::EXPAND, 5 );

	my $sizer = Wx::BoxSizer->new(Wx::HORIZONTAL);
	$sizer->Add( $vsizer, 1, Wx::ALL | Wx::EXPAND, 5 );

	$self->SetSizerAndFit($sizer);
	$self->Layout;

	return $self;
}

sub module {
	$_[0]->{module};
}

sub identity_name {
	$_[0]->{identity_name};
}

sub identity_email {
	$_[0]->{identity_email};
}

sub module_starter_builder {
	$_[0]->{module_starter_builder};
}

sub module_starter_license {
	$_[0]->{module_starter_license};
}

sub module_starter_directory {
	$_[0]->{module_starter_directory};
}

sub ok_clicked {
	$_[0]->main->error('Handler method ok_clicked for event ok.OnButtonClick not implemented');
}

1;

# Copyright 2008-2013 The Padre development team as listed in Padre.pm.
# LICENSE
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl 5 itself.

