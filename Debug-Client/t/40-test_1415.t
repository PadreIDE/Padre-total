#!/usr/bin/env perl

use strict;
use warnings;

# Turn on $OUTPUT_AUTOFLUSH
$| = 1;

use FindBin qw($Bin);
use lib map "$Bin/$_", 'lib', '../lib';

use t::lib::Test_1415;

# run all the test methods in Example::Test
Test::Class->runtests;

1;

__END__
