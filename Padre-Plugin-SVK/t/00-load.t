#!perl

use Test::More tests => 1;

BEGIN {
	use_ok( 'Padre::Plugin::SVK' );
}

diag( "Testing Padre::Plugin::SVK $Padre::Plugin::SVK::VERSION, Perl $], $^X" );
