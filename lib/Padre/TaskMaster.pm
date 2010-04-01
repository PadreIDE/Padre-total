package Padre::TaskMaster;

# Replacement for the current slave driver class.
# Unlike the previous mechanism, the TaskMaster class will only act as
# a router and start/stop controller for threads.
# Worker thread controllers will be contained in a different dedicated class.

use 5.008005;
use strict;
use warnings;
use threads;
use threads::shared;
use Thread::Queue 2.11;

our $VERSION = '0.58';
sub new {
	my $class = shift;
	my $self  = bless {
		thread => undef, # Added to the parent after it is spawned
		inbox  => Thread::Queue->new,
		hosts  => { },
	}, $class;

	# Spawn the object in the thread
	# (Done as two lines just to be sure there isn't some kind
	#  of weird entanglement if I do it as $self->{thread} = .... $self;
	my $thread = threads->create( \&thread, $self );
	$self->{thread} = $thread;

	return $self;
}





######################################################################
# Thread-Only Methods

sub thread {
	my $self = shift;

	# Loop over inbound requests
	while ( my $frozen = $self->{queue}->dequeue ) {
		# Because we'll need to push this down another queue,
		# don't do a proper deserialisation yet. Instead we
		# just pull a message type and destination off the front.
		unless ( $frozen =~ s/^(START)// ) {
			# warn("Unknown or unsupported inbox message");
			next;
		}

		die "CODE INCOMPLETE";
	}

	return;
}

1;
