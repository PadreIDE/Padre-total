package Padre::TaskManager2;

use strict;
use warnings;
use threads;
use threads::shared;
use Thread::Queue 2.11;

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
		# Handle objects for running tasks indexed by handle id
		running => { },
	}, $class;

	return $self;
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
	my $handle = $self->{running}->{ $message->[0] };
	unless ( $handle ) {
		# warn("Received message for a task that is not running");
		return;
	}

	# Pass the message through to the handle
	$handle->on_message( $message );
}

1;
