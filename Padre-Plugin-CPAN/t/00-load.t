#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Padre::Plugin::CPAN' );
}

diag( "Testing Padre::Plugin::CPAN $Padre::Plugin::CPAN::VERSION, Perl $], $^X" );
