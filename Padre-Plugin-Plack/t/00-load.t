#!perl

use Test::More tests => 1;

BEGIN {
	use_ok( 'Padre::Plugin::Plack' );
}

diag( "Testing Padre::Plugin::Plack $Padre::Plugin::Plack::VERSION, Perl $], $^X" );
