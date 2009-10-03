use strict;
use warnings;

use Test::More;

BEGIN {
	if ( not $ENV{DISPLAY} and not $^O eq 'MSWin32' ) {
		plan skip_all => 'Needs DISPLAY';
		exit 0;
	}
}

unless ( $ENV{PADRE_PLUGIN_PARROT} ) {
	plan skip_all => 'Needs PADRE_PLUGIN_PARROT environment variable';
}

eval "use Test::Pod 1.00";
plan skip_all => "Test::Pod 1.00 required for testing POD" if $@;
my @poddirs = qw( blib script );
all_pod_files_ok( all_pod_files(@poddirs) );
