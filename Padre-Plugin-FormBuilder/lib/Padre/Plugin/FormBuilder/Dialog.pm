package Padre::Plugin::FormBuilder::Dialog;

use 5.008;
use strict;
use warnings;
use Padre::Plugin::FormBuilder::FBP ();

our $VERSION = '0.01';
our @ISA     = 'Padre::Plugin::FormBuilder::FBP';





######################################################################
# Customisation

sub new {
	my $class   = shift;
	my $main    = shift;
	my $file    = shift;
	my $dialogs = shift;

	# Create the dialog
	my $self = $class->SUPER::new($main);
	$self->SetTitle("FormBuilder - $file");
	$self->CenterOnParent;

	# Update the form elements
	$self->{file}->SetLabel("Select Dialog:");
	$self->{select}->Append($dialogs);
	$self->{select}->SetSelection(0) if @$dialogs;

	# What to do once we close
	$self->{command} = '';

	return $self;
}

sub command {
	$_[0]->{command};
}

sub selected {
	$_[0]->{select}->GetStringSelection;
}





######################################################################
# Event Handlers

sub generate {
	my $self = shift;
	$self->{command} = 'generate';
	$self->EndModal( Wx::wxID_OK );
}

sub preview {
	my $self = shift;
	$self->{command} = 'generate';
	$self->EndModal( Wx::wxID_OK );
}

1;
