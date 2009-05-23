use strict;
use warnings;

use Test::More;

unless($ENV{AUTHOR_TEST}) {
	plan skip_all => 'Author test';
}

eval "use Test::Pod 1.00";
plan skip_all => "Test::Pod 1.00 required for testing POD" if $@;
my @poddirs = qw( blib script );
all_pod_files_ok( all_pod_files( @poddirs ) );