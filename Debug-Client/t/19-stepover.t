#!/usr/bin/env perl

use strict;
use warnings;

# Turn on $OUTPUT_AUTOFLUSH
$| = 1;

use t::lib::StepOver;

# run all the test methods in Example::Test
Test::Class->runtests;

1;

__END__