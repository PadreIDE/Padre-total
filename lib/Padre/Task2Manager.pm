package Padre::Task2Manager;

use strict;
use warnings;
use threads;
use threads::shared;
use Thread::Queue 2.11;
use Params::Util ();

our $VERSION = '0.58';

# Set up the primary integration event
our $THREAD_SIGNAL : shared;
BEGIN {
	$THREAD_SIGNAL = Wx::NewEventType;
}

# You can instantiate this class only once.
our $SINGLETON;

sub new {
	return $SINGLETON if defined $SINGLETON;

	my $class = shift;
	my $self  = $SINGLETON = bless {
		# Worker management
		minimum_workers => 2,
		maximum_workers => 6,

		# Handle objects, plus index for those running
		handles => { },
		running => { },

		# Unallocated tasks, to be run in FIFO order
		queue => [ ],
	}, $class;

	return $self;
}





######################################################################
# Task Management

sub schedule {
	my $self = shift;
	my $task = Params::Util::_INSTANCE( shift, 'Padre::Task' )
		or die "Invalid task scheduled!"; # TO DO: grace

	# Add to the queue of pending events
	push @{$self->{queue}}, $task;
}





######################################################################
# Signal Handling

sub on_signal {
	my $self  = shift;
	my $event = shift;

	# Deserialize and squelch bad messages
	my $frozen  = $event->GetData;
	my $message = Storable::thaw( \$frozen );
	unless ( ref $message eq 'ARRAY' ) {
		# warn("Unrecognised non-ARRAY message received by a thread");
		return;
	}

	# Fine the task handle for the task
	my $hid    = shift @$message;
	my $handle = $self->{handles}->{$hid};
	unless ( $handle ) {
		# warn("Received message for a task that is not running");
		return;
	}

	# Handle the special startup message
	my $method = shift @$message;
	if ( $method eq 'STARTED' ) {
		# Register the task as running
		$self->{running}->{hid} = $handle;
		return;
	}

	# Any remaining task should be running
	unless ( $self->{running}->{$hid} ) {
		# warn("Received message for a task that is not running");
		return;
	}

	# Handle the special shutdown message
	if ( $method eq 'STOPPED' ) {
		# Remove from the running list to guarentee no more events
		# will be sent to the handle (and thus to the task)
		delete $self->{running}->{$hid};

		# Fire the post-process/cleanup finish method, passing in the
		# completed (and serialised) task object.
		$handle->on_stopped( @$message );

		# Remove from the task list to destroy the task
		delete $self->{task};
		return;
	}

	# Pass the message through to the handle
	$handle->on_message( $method, @$message );
}

1;

# Copyright 2008-2010 The Padre development team as listed in Padre.pm.
# LICENSE
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl 5 itself.
