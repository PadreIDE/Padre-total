package Padre::TaskHandle;

use strict;
use warnings;
use threads;
use threads::shared;
use Thread::Queue 2.11;

our $VERSION  = '0.58';
our $SEQUENCE = 0;





######################################################################
# Constructor and Accessors

sub new {
	my $class = shift;
	my $self  = bless {
		hid  => ++$SEQUENCE,
		task => shift,
	}, $class;
	return $self;
}

sub hid {
	$_[0]->{hid};
}






######################################################################
# Message Passing

sub on_message {
	my $self   = shift;
	my $method = shift;

	# Does the method exist
	unless ( $self->{task}->can($method) ) {
		# A method name provided directly by the Task
		# doesn't exist in the Task. Naughty Task!!!
		# Lacking anything more sane to do, squelch it.
		return;
	}

	# Pass the call down to the task and protect it from itself
	local $@;
	eval {
		$self->{task}->$method(@_);
	};
	if ( $@ ) {
		# A method in the main thread blew up.
		# Beyond catching it and preventing it killing
		# Padre entirely, I'm not sure what else we can
		# really do about it at this point.
		return;
	}

	return;
}

sub on_stopped {
	my $self = shift;

	# The first parameter is the updated Task object.
	# Replace all content in the stored version with that from the
	# event-provided version.
	my $new  = shift;
	my $task = $self->{task};
	%$task = %$new;
	%$new  = ();

	# Execute the finish method in the updated Task object
	local $@;
	eval {
		$self->{task}->finish;
	};
	if ( $@ ) {
		# A method in the main thread blew up.
		# Beyond catching it and preventing it killing
		# Padre entirely, I'm not sure what else we can
		# really do about it at this point.
		return;
	}

	return;
}

1;
