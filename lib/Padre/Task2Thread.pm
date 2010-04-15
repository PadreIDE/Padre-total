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
	_DEBUG(@_);
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
	_DEBUG(@_);
	my $self = shift;

	# Spawn the object into the thread and enter the main runloop
	eval {
		my $thread = threads->create( \&_run, $self );
		print(
			(
				threads::shared::is_shared($thread)
					? "#   Thread object is_shared\n"
					: "#   Thread object not shared\n"
			)
			. (
				threads::shared::is_shared($self)
					? "#   Worker object is_shared\n"
					: "#   Worker object not shared\n"
			)
		);
		$self->{thread} = $thread;
	};
	if ( $@ ) {
		print "#   Class:  " . ref($self) . "\n";
		print "#   Thread: " . threads->self->tid . "\n";
		print "#   Error:  $@\n";
		Carp::confess($@);
	}

	return $self;
}

sub thread {
	_DEBUG(@_);
	$_[0]->{thread} or threads->self;
}

sub join {
	_DEBUG(@_);
	$_[0]->thread->join;
}

sub queue {
	_DEBUG(@_);
	$_[0]->{queue};
}

sub is_thread {
	_DEBUG(@_);
	! defined $_[0]->{thread};
}

sub is_running {
	_DEBUG(@_);
	$_[0]->thread->is_running;
}

sub is_joinable {
	_DEBUG(@_);
	$_[0]->thread->is_joinable;
}

sub is_detached {
	_DEBUG(@_);
	$_[0]->thread->is_detached;
}





######################################################################
# Parent Thread Methods

sub send {
	_DEBUG(@_);
	my $self   = shift;
	my $method = shift;
	unless ( _CAN($self, $method) ) {
		die("Attempted to send message to non-existant method '$method'");
	}

	# Add the message to the queue
	_DEBUG(@_);
	_DEBUG($_[0]->{queue});
	$self->queue->enqueue( [ $method, @_ ] );
	_DEBUG(@_);
	_DEBUG($_[0]->{queue});
	_DEBUG(@_);
	_DEBUG(@_);
	_DEBUG(@_);
	_DEBUG(@_);
	_DEBUG(@_);
	_DEBUG(@_);
	_DEBUG(@_);
	_DEBUG(@_);
	_DEBUG(@_);
	_DEBUG(@_);
	_DEBUG($_[0]->{queue});

	return 1;
}





######################################################################
# Child Thread Methods

# Launch hook to allow run itself to be overloaded
sub _run {
	_DEBUG(@_);
	shift->run(@_);
}

sub run {
	_DEBUG(@_);
	my $self  = shift;
	my $queue = $self->queue;

	# Crash protection
	eval {
		# Loop over inbound requests
		while ( my $message = $queue->dequeue ) {
			_DEBUG($message);
			_DEBUG($message->[1]);
			_DEBUG($message->[1]->{queue});
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

			print "Padre::Task2Thread::run (got message $method)\n";

			# Hand off to the appropriate method.
			# Methods must return true, otherwise the thread
			# will abort processing and end.
			$self->$method(@$message) or last;
		}
	};
	print $@ if $@;

	return;
}





######################################################################
# Support Methods

sub _ARRAY ($) {
	_DEBUG(@_);
	(ref $_[0] eq 'ARRAY' and @{$_[0]}) ? $_[0] : undef;
}

sub _CAN ($$) {
	_DEBUG(@_);
	(Scalar::Util::blessed($_[0]) and $_[0]->can($_[1])) ? $_[0] : undef;
}

sub _DEBUG {
	print '# '
		. threads->self->tid
		. " "
		. (caller(1))[3]
		. "("
		. (
			ref($_[0])
			? Devel::Dumpvar->_refstring($_[0])
			: Devel::Dumpvar->_scalar($_[0])
		)
		. (
			threads::shared::is_shared($_[0])
			? ' :shared'
			: ''
		)
		. ")\n";
}

1;
