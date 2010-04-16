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

# Worker id sequence, so identifiers will be available in objects
# across all instances and threads before the thread has been spawned.
my $SEQUENCE : shared = 0;

# Worker id to native thread id mapping
my %WID2TID : shared = ();





######################################################################
# Constructor and Accessors
sub new {
	_DEBUG(@_);
	bless {
		wid   => ++$SEQUENCE,
		queue => Thread::Queue->new,
	}, $_[0];
}

sub wid {
	_DEBUG(@_);
	$_[0]->{wid};
}

sub queue {
	_DEBUG(@_);
	$_[0]->{queue};
}





######################################################################
# Main Methods

sub spawn {
	_DEBUG(@_);
	my $self = shift;

	# Spawn the object into the thread and enter the main runloop
	$WID2TID{ $self->wid } = threads->create(
		sub {
			$_[0]->run;
		},
		$self,
	)->tid;

	return $self;
}

sub tid {
	_DEBUG(@_);
	$WID2TID{$_[0]->wid};
}

sub thread {
	_DEBUG(@_);
	threads->object( $_[0]->tid );
}

sub join {
	_DEBUG(@_);
	$_[0]->thread->join;
}

sub is_thread {
	_DEBUG(@_);
	$_[0]->tid == threads->self->tid
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
	$self->queue->enqueue( [ $method, @_ ] );

	return 1;
}





######################################################################
# Child Thread Methods

sub run {
	_DEBUG(@_);
	my $self  = shift;
	my $queue = $self->queue;

	# Crash protection
	eval {
		# Loop over inbound requests
		while ( my $message = $queue->dequeue ) {
			print "# Got message - " . scalar(@$message) . " parts\n";
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
