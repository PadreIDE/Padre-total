package Padre::Task2Manager;

use 5.008005;
use strict;
use warnings;
use Params::Util       ();
use Padre::Task2Handle ();
use Padre::Task2Thread ();
use Padre::Task2Worker ();
use Padre::Wx          ();
use Padre::Logger;

our $VERSION = '0.59';

# Set up the primary integration event
our $THREAD_SIGNAL : shared;
BEGIN {
	$THREAD_SIGNAL = Wx::NewEventType();
}

sub new {
	TRACE($_[0]) if DEBUG;
	my $class = shift;
	my $self  = bless {
		threads => 1,   # Are threads enabled
		minimum => 2,   # Workers to launch at startup
		@_,
		workers => [ ], # List of all workers
		handles => { }, # Handles for all active tasks
		running => { }, # Mapping from tid back to parent handle
		queue   => [ ], # Pending tasks to run in FIFO order
	}, $class;
}

sub threads {
	$_[0]->{threads};
}

sub minimum {
	$_[0]->{minimum};
}

sub start {
	TRACE($_[0]) if DEBUG;
	my $self = shift;
	if ( $self->{threads} ) {
		foreach ( 0 .. $self->{minimum} - 1 ) {
			$self->start_thread($_);
		}
	}
	return 1;
}

sub start_thread {
	TRACE($_[0]) if DEBUG;
	my $self   = shift;
	my $master = Padre::Task2Thread->master;
	my $worker = Padre::Task2Worker->new->spawn;
	$self->{workers}->[$_[0]] = $worker;
	return 1;
}

sub stop {
	TRACE($_[0]) if DEBUG;
	my $self = shift;
	if ( $self->{threads} ) {
		Padre::Task2Thread->master->stop;
		foreach ( 0 .. $#{$self->{workers}} ) {
			$self->stop_thread($_);
		}
	}
	return 1;
}

sub stop_thread {
	TRACE($_[0]) if DEBUG;
	my $self = shift;
	delete( $self->{workers}->[$_[0]] )->stop;
	return 1;
}

# Get the next available free child
sub next_thread {
	TRACE($_[0]) if DEBUG;
	my $self = shift;
	foreach my $worker ( @{$self->{workers}} ) {
		# HACK: Always run it in the first one
		return $worker;
	}
	return undef;
}





######################################################################
# Task Management

sub schedule {
	TRACE($_[0]) if DEBUG;
	my $self = shift;
	my $task = Params::Util::_INSTANCE(shift, 'Padre::Task2');
	unless ( $task ) {
		die "Invalid task scheduled!"; # TO DO: grace
	}

	# Add to the queue of pending events
	push @{$self->{queue}}, $task;

	# Iterate the management loop
	$self->step;
}

sub step {
	TRACE($_[0]) if DEBUG;
	my $self    = shift;
	my $queue   = $self->{queue};
	my $running = $self->{running};

	# Is there anything in the queue to run
	return unless @$queue;

	# Shortcut if there is nowhere to run the task
	if ( $self->{threads} ) {
		unless ( $self->{minimum} > scalar keys %$running ) {
			return;
		}
	}

	# Fetch and prepare the next task
	my $task   = shift @$queue;
	my $handle = Padre::Task2Handle->new( $task );
	my $hid    = $handle->hid;

	# Run the pre-run step in the main thread
	unless ( $handle->prepare ) {
		die "Task ->prepare method failed";
	}

	# Register the handle for Wx event callbacks
	$running->{$hid} = $handle;

	# Find the next available worker
	my $worker = $self->next_thread;
	unless ( $worker ) {
		die "Unexpectedly failed to find a free worker thread";
	}

	# Generate the message to the thread
	$DB::single = $DB::single = 1;
	my $message = [
		'run_task',
		1,
	];
}





######################################################################
# Signal Handling

sub on_signal {
	TRACE($_[0]) if DEBUG;
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
		$self->{running}->{$hid} = $handle;
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
