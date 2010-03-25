#!perl

use Test::More tests => 1;

BEGIN {
	use_ok( 'Padre::Plugin::PHP' );
}

diag( "Testing Padre::Plugin::PHP $Padre::Plugin::PHP::VERSION, Perl $], $^X" );
