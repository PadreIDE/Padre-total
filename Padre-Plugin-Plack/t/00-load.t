#!perl

use Test::More tests => 3;

BEGIN {
	use_ok( 'Padre::Plugin::Plack' );
	use_ok( 'Padre::Plugin::Plack::Panel' );
	use_ok( 'Padre::Document::PSGI' );
}

diag( "Testing Padre::Plugin::Plack $Padre::Plugin::Plack::VERSION, Perl $], $^X" );
