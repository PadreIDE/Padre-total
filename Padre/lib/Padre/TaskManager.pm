package Padre::TaskManager;

use 5.008005;
use strict;
use warnings;
use Params::Util             ();
use Padre::TaskHandle        ();
use Padre::TaskThread        ();
use Padre::TaskWorker        ();
use Padre::Wx                ();
use Padre::Wx::Role::Conduit ();
use Padre::Logger;

our $VERSION        = '0.69';
our $BACKCOMPATIBLE = '0.66';

# Set up the primary integration event
our $THREAD_SIGNAL : shared;

BEGIN {
	$THREAD_SIGNAL = Wx::NewEventType();
}

sub new {
	TRACE( $_[0] ) if DEBUG;
	my $class   = shift;
	my %param   = @_;
	my $conduit = delete $param{conduit};
	my $self    = bless {
		active  => 0, # Are we running at the moment
		threads => 1, # Are threads enabled
		minimum => 0, # Workers to launch at startup
		maximum => 3, # The most workers we should use
		%param,
		workers => [], # List of all workers
		handles => {}, # Handles for all active tasks
		running => {}, # Mapping from tid back to parent handle
		queue   => [], # Pending tasks to run in FIFO order
	}, $class;

	# Do the initialisation needed for the event conduit
	unless ( Params::Util::_INSTANCE( $conduit, 'Padre::Wx::Role::Conduit' ) ) {
		die("Failed to provide an event conduit for the TaskManager");
	}
	$conduit->conduit_init($self);

	return $self;
}

sub active {
	TRACE( $_[0] ) if DEBUG;
	$_[0]->{active};
}

sub threads {
	TRACE( $_[0] ) if DEBUG;
	$_[0]->{threads};
}

sub minimum {
	TRACE( $_[0] ) if DEBUG;
	$_[0]->{minimum};
}

sub maximum {
	TRACE( $_[0] ) if DEBUG;
	$_[0]->{maximum};
}

sub start {
	TRACE( $_[0] ) if DEBUG;
	my $self = shift;
	if ( $self->{threads} ) {
		foreach ( 0 .. $self->{minimum} - 1 ) {
			$self->start_thread($_);
		}
	}
	$self->{active} = 1;
	$self->step;
}

sub stop {
	TRACE( $_[0] ) if DEBUG;
	my $self = shift;
	$self->{active} = 0;
	if ( $self->{threads} ) {
		foreach ( 0 .. $#{ $self->{workers} } ) {
			$self->stop_thread($_);
		}
		Padre::TaskThread->master->stop;
	}
	return 1;
}

sub start_thread {
	TRACE( $_[0] ) if DEBUG;
	my $self   = shift;
	my $master = Padre::TaskThread->master;
	my $worker = Padre::TaskWorker->new->spawn;
	$self->{workers}->[ $_[0] ] = $worker;
	return $worker;
}

sub stop_thread {
	TRACE( $_[0] ) if DEBUG;
	my $self = shift;
	delete( $self->{workers}->[ $_[0] ] )->stop;
	return 1;
}

# Get the next available free child
sub next_thread {
	TRACE( $_[0] ) if DEBUG;
	my $self    = shift;
	my $workers = $self->{workers};

	# Find the first free worker of any kind
	foreach my $worker (@$workers) {
		next if $worker->handle;
		return $worker;
	}

	# Create a new worker if we can
	if ( @$workers < $self->maximum ) {
		return $self->start_thread( scalar @$workers );
	}

	return undef;
}

# Get the best available child for a particular task
sub best_thread {
	TRACE( $_[0] ) if DEBUG;
	my $self    = shift;
	my $handle  = shift;
	my $workers = $self->{workers};
	my @unused  = grep { not $_->handle } @$workers;

	# First try to find a specialist.
	# Any of them will do at this point, no futher work needed.
	foreach my $worker (@unused) {
		next unless $worker->{seen}->{ $handle->class };
		return $worker;
	}

	# Bias towards maximum reuse of a smaller number of threads.
	# This will (hopefully) allow the most stale threads to swap
	# better, and will simplify decisions on when to clean up
	# excessive threads.
	if ( defined $unused[0] ) {
		return $unused[0];
	}

	# Create a new worker if we can
	if ( @$workers < $self->maximum ) {
		return $self->start_thread( scalar @$workers );
	}

	return undef;
}





######################################################################
# Task Management

sub schedule {
	TRACE( $_[1] ) if DEBUG;
	my $self = shift;
	my $task = Params::Util::_INSTANCE( shift, 'Padre::Task' );
	unless ($task) {
		die "Invalid task scheduled!"; # TO DO: grace
	}

	# Add to the queue of pending events
	push @{ $self->{queue} }, $task;

	# Iterate the management loop
	$self->step;
}

sub step {
	TRACE( $_[0] ) if DEBUG;
	my $self    = shift;
	my $queue   = $self->{queue};
	my $handles = $self->{handles};

	# Shortcut if not allowed to run, or nothing to do
	return 1 unless $self->{active};
	return 1 unless @$queue;

	# Shortcut if there is nowhere to run the task
	if ( $self->{threads} ) {
		if ( scalar keys %$handles >= $self->{maximum} ) {
			return 1;
		}
	}

	# Fetch and prepare the next task
	my $task   = shift @$queue;
	my $handle = Padre::TaskHandle->new($task);
	my $hid    = $handle->hid;

	# Run the pre-run step in the main thread
	unless ( $handle->prepare ) {

		# Task wishes to abort itself. Oblige it.
		undef $handle;

		# Move on to the next task
		return $self->step;
	}

	# Register the handle for Wx event callbacks
	$handles->{$hid} = $handle;

	# Find the next/best worker for the task
	my $worker = $self->best_thread($handle) or return;

	# Send the task to the worker for execution
	$worker->send_task($handle);

	# Continue to the next iteration
	return $self->step;
}





######################################################################
# Signal Handling

sub on_signal {
	TRACE( $_[0] ) if DEBUG;
	my $self  = shift;
	my $event = shift;

	# Deserialize and squelch bad messages
	my $frozen = $event->GetData;
	my $message = eval { Storable::thaw($frozen); };
	if ($@) {

		# warn("Exception deserialising message from thread ('$frozen')");
		return;
	}
	unless ( ref $message eq 'ARRAY' ) {

		# warn("Unrecognised non-ARRAY message received by a thread");
		return;
	}

	# Fine the task handle for the task
	my $hid = shift @$message;
	my $handle = $self->{handles}->{$hid} or return;

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

		# Free up the worker thread for other tasks
		foreach my $worker ( @{ $self->{workers} } ) {
			next unless defined $worker->handle;
			next unless $worker->handle == $hid;
			$worker->handle(undef);
			last;
		}

		# Fire the post-process/cleanup finish method, passing in the
		# completed (and serialised) task object.
		$handle->on_stopped(@$message);

		# Remove from the task list to destroy the task
		delete $self->{handles}->{$hid};

		# This should have released a worker to process
		# a new task, kick off the next scheduling iteration.
		return $self->step;
	}

	# Pass the message through to the handle
	$handle->on_message( $method, @$message );
}

1;

# Copyright 2008-2010 The Padre development team as listed in Padre.pm.
# LICENSE
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl 5 itself.
