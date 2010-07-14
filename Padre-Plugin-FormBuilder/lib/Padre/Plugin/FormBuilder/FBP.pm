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

	$self->{file} = Wx::StaticText->new(
		$self,
		-1,
		Wx::gettext('Importing:'),
	);

	$self->{line1} = Wx::StaticLine->new(
		$self,
		-1,
		Wx::wxDefaultPosition,
		Wx::wxDefaultSize,
		Wx::wxLI_HORIZONTAL,
	);

	$self->{select} = Wx::Choice->new(
		$self,
		-1,
		Wx::wxDefaultPosition,
		Wx::wxDefaultSize,
		[ ],
	);

	$self->{m_checkBox1} = Wx::CheckBox->new(
		$self,
		-1,
		Wx::gettext('Check Me!'),
		Wx::wxDefaultPosition,
		Wx::wxDefaultSize,
	);

	$self->{m_checkBox2} = Wx::CheckBox->new(
		$self,
		-1,
		Wx::gettext('Check Me!'),
		Wx::wxDefaultPosition,
		Wx::wxDefaultSize,
	);

	$self->{m_checkBox3} = Wx::CheckBox->new(
		$self,
		-1,
		Wx::gettext('Check Me!'),
		Wx::wxDefaultPosition,
		Wx::wxDefaultSize,
	);

	$self->{m_checkBox4} = Wx::CheckBox->new(
		$self,
		-1,
		Wx::gettext('Check Me!'),
		Wx::wxDefaultPosition,
		Wx::wxDefaultSize,
	);

	$self->{line2} = Wx::StaticLine->new(
		$self,
		-1,
		Wx::wxDefaultPosition,
		Wx::wxDefaultSize,
		Wx::wxLI_HORIZONTAL,
	);

	$self->{preview} = Wx::Button->new(
		$self,
		-1,
		Wx::gettext('Preview'),
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
		Wx::gettext('Generate'),
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
		Wx::gettext('Cancel'),
	);

	my $gSizer1 = Wx::GridSizer->new( 2, 2, 0, 0 );
	$gSizer1->Add( $self->{m_checkBox1}, 0, Wx::wxALL, 5 );
	$gSizer1->Add( $self->{m_checkBox2}, 0, Wx::wxALL, 5 );
	$gSizer1->Add( $self->{m_checkBox3}, 0, Wx::wxALL, 5 );
	$gSizer1->Add( $self->{m_checkBox4}, 0, Wx::wxALL, 5 );

	my $buttons = Wx::BoxSizer->new( Wx::wxHORIZONTAL );
	$buttons->Add( $self->{preview}, 0, Wx::wxALL, 5 );
	$buttons->Add( $self->{generate}, 0, Wx::wxBOTTOM | Wx::wxTOP, 5 );
	$buttons->Add( 50, 0, 1, Wx::wxEXPAND, 5 );
	$buttons->Add( $self->{cancel}, 0, Wx::wxALL, 5 );

	my $sizer2 = Wx::BoxSizer->new( Wx::wxVERTICAL );
	$sizer2->Add( $self->{file}, 0, Wx::wxALL | Wx::wxEXPAND, 5 );
	$sizer2->Add( $self->{line1}, 0, Wx::wxBOTTOM | Wx::wxEXPAND | Wx::wxTOP, 0 );
	$sizer2->Add( $self->{select}, 0, Wx::wxALL | Wx::wxEXPAND, 5 );
	$sizer2->Add( $gSizer1, 1, Wx::wxBOTTOM | Wx::wxEXPAND, 5 );
	$sizer2->Add( $self->{line2}, 0, Wx::wxEXPAND, 0 );
	$sizer2->Add( $buttons, 0, Wx::wxEXPAND, 5 );

	my $sizer1 = Wx::BoxSizer->new( Wx::wxHORIZONTAL );
	$sizer1->Add( $sizer2, 1, Wx::wxEXPAND, 5 );

	$self->SetSizer($sizer1);
	$self->Layout;
	$sizer1->Fit($self);

	return $self;
}

sub preview {
	my $self  = shift;
	my $event = shift;

	die 'EVENT HANDLER NOT IMPLEMENTED';
}

sub generate {
	my $self  = shift;
	my $event = shift;

	die 'EVENT HANDLER NOT IMPLEMENTED';
}

1;
