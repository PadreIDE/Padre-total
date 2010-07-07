package Padre::Plugin::FormBuilder::FBP;

use 5.008;
use strict;
use warnings;
use Padre::Wx             ();
use Padre::Wx::Role::Main ();

our $VERSION = '0.01';
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
		'',
		Wx::wxDefaultPosition,
		Wx::wxDefaultSize,
		Wx::wxDEFAULT_DIALOG_STYLE,
	);

	my $file = Wx::StaticText->new(
		$self,
		-1,
		'Importing: $file',
	);

	my $line1 = Wx::StaticLine->new(
		$self,
		-1,
		Wx::wxDefaultPosition,
		Wx::wxDefaultSize,
	);

	$self->{select} = Wx::Choice->new(
		$self,
		-1,
		Wx::wxDefaultPosition,
		Wx::wxDefaultSize,
		[ ],
	);

	my $line2 = Wx::StaticLine->new(
		$self,
		-1,
		Wx::wxDefaultPosition,
		Wx::wxDefaultSize,
	);

	$self->{preview} = Wx::Button->new(
		$self,
		-1,
		'Preview',
	);

	Wx::Event::EVT_BUTTON(
		$self,
		$self->{preview},
		sub {
			shift->preview(@_);
		},
	);

	$self->{generate} = Wx::Button->new(
		$self,
		-1,
		'Generate',
	);

	Wx::Event::EVT_BUTTON(
		$self,
		$self->{generate},
		sub {
			shift->generate(@_);
		},
	);

	$self->{cancel} = Wx::Button->new(
		$self,
		Wx::wxID_CANCEL,
		'Cancel',
	);

	my $buttons = Wx::BoxSizer->new( Wx::wxHORIZONTAL );
	$buttons->Add( $self->{preview}, 0, Wx::wxALL, 5 );
	$buttons->Add( $self->{generate}, 0, Wx::wxBOTTOM | Wx::wxTOP, 5 );
	$buttons->AddSpacer(50);
	$buttons->Add( $self->{cancel}, 0, Wx::wxALL, 5 );

	my $sizer2 = Wx::BoxSizer->new( Wx::wxVERTICAL );
	$sizer2->Add( $file, 0, Wx::wxALL | Wx::wxEXPAND, 5 );
	$sizer2->Add( $line1, 0, Wx::wxBOTTOM | Wx::wxEXPAND | Wx::wxTOP, 0 );
	$sizer2->Add( $self->{select}, 0, Wx::wxALL | Wx::wxEXPAND, 5 );
	$sizer2->AddSpacer(50);
	$sizer2->Add( $line2, 0, Wx::wxEXPAND, 0 );
	$sizer2->Add( $buttons, 0, Wx::wxEXPAND, 5 );

	my $sizer1 = Wx::BoxSizer->new( Wx::wxHORIZONTAL );
	$sizer1->Add( $sizer2, 1, Wx::wxEXPAND, 5 );

	$self->SetSizer($sizer1);
	$sizer1->SetSizeHints($self);

	return $self;
}

sub preview {
	my $self  = shift;
	my $event = shift;

	die 'TO BE COMPLETED';
}

sub generate {
	my $self  = shift;
	my $event = shift;

	die 'TO BE COMPLETED';
}

1;
