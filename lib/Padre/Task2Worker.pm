package Padre::Task2Worker;

# Object that represents the worker thread

use 5.008005;
use strict;
use warnings;
use Padre::Task2Thread ();

our $VERSION = '0.58';
our @ISA     = 'Padre::Task2Thread';

sub new {
	my $self = shift->SUPER::new(@_);

	# Add the storage for the currently active task handle
	$self->{task} = undef;

	return $self;
}

sub task {
	$_[0]->{task};
}





#######################################################################
# Parent Methods





######################################################################
# Worker Thread Methods

1;
