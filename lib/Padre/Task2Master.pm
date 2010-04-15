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
	_DEBUG(@_);
	my $self = shift->SUPER::new(@_);

	# Worker storage
	$self->{workers} = { };

	return $self;
}

# Add a worker object to the pool, spawning it from the master
sub add {
	_DEBUG(@_);
	shift->send( 'spawn_child', @_ );
}





######################################################################
# Master Thread Methods

# Cleans up running hosts and then returns false,
# which instructs the main loop to exit and return.
sub shutdown {
	_DEBUG(@_);
	return 0;
}

# Spawn a worker object off the current thread
sub spawn_child {
	_DEBUG(@_);
	$_[0]->{workers}->{ $_[1]->wid } = $_[1]->spawn;

	# Do not exit after this command
	return 1;
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

# Copyright 2008-2010 The Padre development team as listed in Padre.pm.
# LICENSE
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl 5 itself.
