#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Padre::Plugin::Parrot' );
}

diag( "Testing Padre::Plugin::Parrot $Padre::Plugin::Parrot::VERSION, Perl $], $^X" );
