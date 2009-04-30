#!perl

use Test::More tests => 1;

BEGIN {
	use_ok( 'Padre::Plugin::Mojolicious' );
}

diag( "Testing Padre::Plugin::Mojolicious $Padre::Plugin::Mojolicious::VERSION, Perl $], $^X" );
