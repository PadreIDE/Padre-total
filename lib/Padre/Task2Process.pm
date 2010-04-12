package Padre::Task2Process;

use 5.008;
use strict;
use warnings;
use Carp         ();
use Padre::Task2 ();

our $VERSION = '0.59';
our @ISA     = 'Padre::Task2';





######################################################################
# Process API Methods

# Pass upstream to our handle
sub message {
	my $self = shift;

	# Check the message
	my $method = shift;
	unless ( $self->running ) {
		croak("Attempted to send message while not in a worker thread");
	}
	unless ( $method and $self->can($method) ) {
		croak("Attempted to send message to non-existant method '$method'");
	}

	# Hand off to our parent handle
	$self->handle->message($method, @_);
}

1;
