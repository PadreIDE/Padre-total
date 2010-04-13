package Padre::Task2Master;

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
use Scalar::Util ();

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
	my $thread = threads->create( \&run, $self );
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

sub send {
	my $self   = shift;
	my $method = shift;
	unless ( _CAN($self, $method) ) {
		die("Attempted to send message to non-existant method '$method'");
	}

	# Add the message to the queue
	$self->queue->enqueue( [ $method, @_ ] );

	return 1;
}





######################################################################
# Master Thread Methods

sub run {
	my $self  = shift;
	my $queue = $self->queue;

	# Loop over inbound requests
	while ( my $message = $queue->dequeue ) {
		unless ( _ARRAY($message) ) {
			# warn("Message is not an ARRAY reference");
			next;
		}

		# Check the message type
		my $method = shift @$message;
		unless ( _CAN($self, $method) ) {
			# warn("Illegal message type");
			next;
		}

		# Hand off to the appropriate method.
		# Methods must return true, otherwise the thread
		# will abort processing and end.
		$self->$method(@$message) or last;
	}

	return;
}

# Cleans up running hosts and then returns false,
# which instructs the main loop to exit and return.
sub shutdown {
	my $self = shift;

	# Kill all running task hosts
	foreach my $host ( @{$self->{hosts}} ) {
		die "CODE INCOMPLETE";
	}

	return 0;
}





######################################################################
# Support Methods

sub _ARRAY ($) {
	(ref $_[0] eq 'ARRAY' and @{$_[0]}) ? $_[0] : undef;
}

sub _CAN ($$) {
	(Scalar::Util::blessed($_[0]) and $_[0]->can($_[1])) ? $_[0] : undef;
}

1;
