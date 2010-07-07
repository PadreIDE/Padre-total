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
	my $self = shift->SUPER::new(@_);

	$self->CenterOnParent;

	return $self;
}





######################################################################
# Event Handlers

sub generate {
	my $self = shift;

	die "CODE INCOMPLETE";
}

1;
