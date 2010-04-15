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
use Padre::Task2Thread ();

our $VERSION = '0.58';
our @ISA     = 'Padre::Task2Thread';





#######################################################################
# Main Thread Methods

sub new {
	my $self = shift->SUPER::new(@_);

	# Worker storage
	$self->{workers} = { };

	return $self;
}

# Add a worker object to the pool, spawning it from the master
sub add {
	shift->send( 'spawn_child', @_ );
}





######################################################################
# Master Thread Methods

# Cleans up running hosts and then returns false,
# which instructs the main loop to exit and return.
sub shutdown {
	return 0;
}

# Spawn a worker object off the current thread
sub spawn_child {
	$_[0]->{workers}->{ $_[1]->wid } = $_[1]->spawn;
}

1;
