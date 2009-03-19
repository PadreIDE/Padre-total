#!perl

use Test::More tests => 1;

BEGIN {
	use_ok( 'Padre::Plugin::ClassSniff' );
}

diag( "Testing Padre::Plugin::ClassSniff $Padre::Plugin::ClassSniff::VERSION, Perl $], $^X" );
