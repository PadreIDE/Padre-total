#!perl

use Test::More tests => 2;

BEGIN {
	use_ok( 'Padre::Plugin::CSS' );
	use_ok( 'Padre::Document::CSS' );
}

diag( "Testing Padre::Plugin::CSS $Padre::Plugin::CSS::VERSION, Perl $], $^X" );
