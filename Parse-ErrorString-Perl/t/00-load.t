#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Parse::ErrorString::Perl' );
}

diag( "Testing Parse::ErrorString::Perl $Parse::ErrorString::Perl::VERSION, Perl $], $^X" );
