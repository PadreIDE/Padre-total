package Padre::Task2Worker;

# Object that represents the worker thread

use 5.008005;
use strict;
use warnings;
use Padre::Task2Thread ();
use Padre::Logger;

our $VERSION = '0.59';
our @ISA     = 'Padre::Task2Thread';

sub task {
	TRACE($_[0]) if DEBUG;
	$_[0]->{task};
}





#######################################################################
# Main Thread Methods





######################################################################
# Worker Thread Methods





1;

# Copyright 2008-2010 The Padre development team as listed in Padre.pm.
# LICENSE
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl 5 itself.
