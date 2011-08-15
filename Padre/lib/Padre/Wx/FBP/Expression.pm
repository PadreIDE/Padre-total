package Padre::Wx::FBP::Expression;

## no critic

# This module was generated by Padre::Plugin::FormBuilder::Perl.
# To change this module edit the original .fbp file and regenerate.
# DO NOT MODIFY THIS FILE BY HAND!

use 5.008;
use strict;
use warnings;
use Padre::Wx ();
use Padre::Wx::Role::Main ();

our $VERSION = '0.89';
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
		Wx::gettext("Evaluate Expression"),
		Wx::wxDefaultPosition,
		Wx::wxDefaultSize,
		Wx::wxDEFAULT_DIALOG_STYLE | Wx::wxRESIZE_BORDER,
	);

	$self->{code} = Wx::TextCtrl->new(
		$self,
		-1,
		"",
		Wx::wxDefaultPosition,
		Wx::wxDefaultSize,
		Wx::wxTE_PROCESS_ENTER,
	);

	Wx::Event::EVT_TEXT(
		$self,
		$self->{code},
		sub {
			shift->on_text(@_);
		},
	);

	Wx::Event::EVT_TEXT_ENTER(
		$self,
		$self->{code},
		sub {
			shift->on_text_enter(@_);
		},
	);

	$self->{evaluate} = Wx::Button->new(
		$self,
		-1,
		Wx::gettext("Evaluate"),
		Wx::wxDefaultPosition,
		Wx::wxDefaultSize,
	);

	Wx::Event::EVT_BUTTON(
		$self,
		$self->{evaluate},
		sub {
			shift->on_evaluate(@_);
		},
	);

	$self->{output} = Wx::TextCtrl->new(
		$self,
		-1,
		"",
		Wx::wxDefaultPosition,
		Wx::wxDefaultSize,
		Wx::wxTE_MULTILINE | Wx::wxTE_READONLY,
	);
	$self->{output}->SetMinSize( [ 500, 400 ] );
	$self->{output}->SetFont(
		Wx::Font->new( Wx::wxNORMAL_FONT->GetPointSize, 76, 90, 90, 0, "" )
	);

	my $bSizer36 = Wx::BoxSizer->new(Wx::wxHORIZONTAL);
	$bSizer36->Add( $self->{code}, 1, Wx::wxALIGN_CENTER_VERTICAL | Wx::wxALL | Wx::wxEXPAND, 3 );
	$bSizer36->Add( $self->{evaluate}, 0, Wx::wxALL, 3 );

	my $bSizer35 = Wx::BoxSizer->new(Wx::wxVERTICAL);
	$bSizer35->Add( $bSizer36, 0, Wx::wxEXPAND, 3 );
	$bSizer35->Add( $self->{output}, 1, Wx::wxALL | Wx::wxEXPAND, 3 );

	$self->SetSizerAndFit($bSizer35);
	$self->Layout;

	return $self;
}

sub code {
	$_[0]->{code};
}

sub evaluate {
	$_[0]->{evaluate};
}

sub output {
	$_[0]->{output};
}

sub on_text {
	$_[0]->main->error('Handler method on_text for event code.OnText not implemented');
}

sub on_text_enter {
	$_[0]->main->error('Handler method on_text_enter for event code.OnTextEnter not implemented');
}

sub on_evaluate {
	$_[0]->main->error('Handler method on_evaluate for event evaluate.OnButtonClick not implemented');
}

1;

# Copyright 2008-2011 The Padre development team as listed in Padre.pm.
# LICENSE
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl 5 itself.

