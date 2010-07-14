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
	$self->CenterOnParent;

	# Update the form elements
	$self->{file}->SetLabel(
		$self->{file}->GetLabel
		. " $file"
	);
	foreach my $dialog ( @$dialogs ) {
		$self->{select}->Append($dialog);
	}

	return $self;
}





######################################################################
# Event Handlers


1;
