#!/usr/bin/env perl

use strict;
use warnings;

# Turn on $OUTPUT_AUTOFLUSH
$| = 1;

use Test::More tests => 1;

BEGIN {
	use_ok('Padre::Plugin::PerlCritic');
}

diag("Testing Padre::Plugin::PerlCritic $Padre::Plugin::PerlCritic::VERSION");

done_testing( );

1;

__END__
