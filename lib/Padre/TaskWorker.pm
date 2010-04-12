package Padre::TaskWorker;

# Object that represents the worker thread

use 5.008005;
use strict;
use warnings;
use threads;
use threads::shared;
use Thread::Queue 2.11;

our $VERSION = '0.58';

sub new {
	my $class = shift;

	# Create the object so it can be cloned into the thread
	my $self = bless {
		thread => undef, # Added to the parent after it is spawned
		queue  => Thread::Queue->new,
		task   => undef, # The current active task
	}, $class;

	return $self;
}

sub thread {
	$_[0]->{thread};
}

sub queue {
	$_[0]->{queue};
}

sub task {
	$_[0]->{task};
}





######################################################################
# Main Thread Methods





######################################################################
# Master Thread Methods





######################################################################
# Worker Thread Methods

sub run {
	my $self  = shift;
	my $queue = $self->queue;

	# Loop over inbound requests
	while ( my $message = $queue->dequeue ) {
		unless ( defined $message and not ref $message and ref $message eq 'ARRAY' ) {
			# warn("Message is not an ARRAY reference");
			next;
		}

		# Check the message type
		my $type = shift @$message;
		unless ( defined $type and not ref $type ) {
			# warn("Illegal message type");
			next;
		}

		die "CODE INCOMPLETE";
	}

	return;
}

1;
