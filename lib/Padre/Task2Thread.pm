package Padre::Task2Thread;

# Cleanly encapsulated object for a thread that does work based 
# on packaged method calls passed via a shared queue.

use 5.008005;
use strict;
use warnings;
use threads;
use threads::shared;
use Thread::Queue 2.11;
use Scalar::Util ();
use Carp ();

our $VERSION = '0.58';
sub new {
	print "Padre::Task2Thread::new\n";
	my $class = shift;

	# Create the object so it can be cloned into the thread
	my $self = bless {
		# Added to the parent after it is spawned
		thread => undef,
		queue  => undef,
		@_,
	}, $class;

	# Set the queue if none was provided
	$self->{queue} ||= Thread::Queue->new;

	return $self;
}

sub spawn {
	print "Padre::Task2Thread::spawn\n";
	my $self = shift;

	# Spawn the object into the thread and enter the main runloop
	eval {
		my $thread = threads->create( \&_run, $self );
		
		
		
		$self->{thread} = $thread;
	};
	if ( $@ ) {
		print "Class:  " . ref($self) . "\n";
		print "Thread: " . threads->self->tid . "\n";
		print "Error:  $@\n";
		Carp::confess($@);
	}

	return $self;
}

sub thread {
	print "Padre::Task2Thread::thread\n";
	$_[0]->{thread} or threads->self;
}

sub join {
	print "Padre::Task2Thread::join\n";
	$_[0]->thread->join;
}

sub queue {
	print "Padre::Task2Thread::queue\n";
	$_[0]->{queue};
}

sub is_thread {
	print "Padre::Task2Thread::is_thread\n";
	! defined $_[0]->{thread};
}

sub is_running {
	print "Padre::Task2Thread::is_running\n";
	$_[0]->thread->is_running;
}

sub is_joinable {
	print "Padre::Task2Thread::is_joinable\n";
	$_[0]->thread->is_joinable;
}

sub is_detached {
	print "Padre::Task2Thread::is_detached\n";
	$_[0]->thread->is_detached;
}





######################################################################
# Parent Thread Methods

sub send {
	print "Padre::Task2Thread::send\n";
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
# Child Thread Methods

# Launch hook to allow run itself to be overloaded
sub _run {
	print "Padre::Task2Thread::_run\n";
	shift->run(@_);
}

sub run {
	print "Padre::Task2Thread::run\n";
	my $self  = shift;
	my $queue = $self->queue;

	# Crash protection
	eval {
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
	};
	if ( $@ ) {
		print $@;
	}

	return;
}





######################################################################
# Support Methods

sub _ARRAY ($) {
	print "Padre::Task2Thread::_ARRAY\n";
	(ref $_[0] eq 'ARRAY' and @{$_[0]}) ? $_[0] : undef;
}

sub _CAN ($$) {
	print "Padre::Task2Thread::_CAN\n";
	(Scalar::Util::blessed($_[0]) and $_[0]->can($_[1])) ? $_[0] : undef;
}

1;
