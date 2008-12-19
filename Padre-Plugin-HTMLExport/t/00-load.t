#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Padre::Plugin::HTMLExport' );
}

diag( "Testing Padre::Plugin::HTMLExport $Padre::Plugin::HTMLExport::VERSION, Perl $], $^X" );
