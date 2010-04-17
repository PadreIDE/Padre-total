package Padre::Task2Worker;

# Object that represents the worker thread

use 5.008005;
use strict;
use warnings;
use Padre::Task2Thread ();
use Padre::Logger;

our $VERSION = '0.58';
our @ISA     = 'Padre::Task2Thread';

sub new {
	TRACE($_[0]) if DEBUG;
	my $self = shift->SUPER::new(@_);

	# Add the storage for the currently active task handle
	$self->{task} = undef;

	return $self;
}

sub wid {
	TRACE($_[0]) if DEBUG;
	$_[0]->{wid};
}

sub task {
	TRACE($_[0]) if DEBUG;
	$_[0]->{task};
}

sub unshare {
	TRACE($_[0]) if DEBUG;
	my $self  = shift;
	my $class = ref($self);
	return bless {
		queue => $self->queue,
		wid   => $self->wid + 0,
	}, $class;
}





#######################################################################
# Main Thread Methods





######################################################################
# Worker Thread Methods

# If we are waiting for a new task, there's nothing for us
# to do other than return false.
sub shutdown {
	TRACE($_[0]) if DEBUG;
	return 0;
}

1;

# Copyright 2008-2010 The Padre development team as listed in Padre.pm.
# LICENSE
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl 5 itself.
