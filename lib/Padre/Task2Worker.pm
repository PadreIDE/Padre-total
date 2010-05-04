package Padre::Task2Worker;

# Object that represents the worker thread

use 5.008005;
use strict;
use warnings;
use Scalar::Util       ();
use Padre::Task2Thread ();
use Padre::Logger;

our $VERSION = '0.59';
our @ISA     = 'Padre::Task2Thread';

sub handle {
	TRACE($_[0]) if DEBUG;
	$_[0]->{handle};
}





#######################################################################
# Main Thread Methods





######################################################################
# Worker Thread Methods

sub task {
	TRACE($_[0]) if DEBUG;
	my $self = shift;

	# Deserialize the task handle
	TRACE("Loading Padre::Task2Handle") if DEBUG;
	require Padre::Task2Handle;
	TRACE("Inflating handle object") if DEBUG;
	my $handle = Padre::Task2Handle->from_array( shift );

	# Execute the task (ignore the result) and signal as we go
	eval {
		TRACE("Calling ->started") if DEBUG;
		$handle->started;
		TRACE("Calling ->run") if DEBUG;
		$handle->run;
		TRACE("Calling ->stopped") if DEBUG;
		$handle->stopped;
	};
	if ( $@ ) {
		TRACE($@) if DEBUG;
	};

	# Continue to the next task
	return 1;
}

1;

# Copyright 2008-2010 The Padre development team as listed in Padre.pm.
# LICENSE
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl 5 itself.
