package Padre::Task2Worker;

# Object that represents the worker thread

use 5.008005;
use strict;
use warnings;
use Padre::Task2Thread ();

our $VERSION = '0.58';
our @ISA     = 'Padre::Task2Thread';

sub new {
	_DEBUG(@_);
	my $self = shift->SUPER::new(@_);

	# Add the storage for the currently active task handle
	$self->{task} = undef;

	# Without a worker id, we have no way to map task
	# operations through to the right worker.
	unless ( $self->wid ) {
		die("Did not provide an 'wid' worker identifier");
	}

	return $self;
}

sub wid {
	_DEBUG(@_);
	$_[0]->{wid};
}

sub task {
	_DEBUG(@_);
	$_[0]->{task};
}





#######################################################################
# Main Thread Methods





######################################################################
# Worker Thread Methods

# If we are waiting for a new task, there's nothing for us
# to do other than return false.
sub shutdown {
	_DEBUG(@_);
	return 0;
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
			? ':shared'
			: ''
		)
		. ")\n";
}

1;

# Copyright 2008-2010 The Padre development team as listed in Padre.pm.
# LICENSE
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl 5 itself.
