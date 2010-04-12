package Padre::TaskMaster;

# Replacement for the current slave driver class.
#
# Unlike the previous mechanism, the TaskMaster class will only act as
# a router and start/stop controller for threads.
#
# Worker thread implementation code will be contained in a different
# dedicated class.
#
# This module needs to be ABSOLUTELY ruthless about loading as few
# modules as possible. Every byte we consume here will need to be spent
# again for every single worker thread.

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
		hosts  => [ ],
	}, $class;

	# Spawn the object in the thread.
	# (Done as two lines just to be sure there isn't some kind
	# of weird entanglement if I do it as $self->{thread} = .... $self;
	my $thread = threads->create( \&thread, $self );
	$self->{thread} = $thread;

	return $self;
}

sub thread {
	$_[0]->{thread};
}

sub queue {
	$_[0]->{queue};
}





######################################################################
# Main Thread Methods





######################################################################
# Master Thread Methods

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
