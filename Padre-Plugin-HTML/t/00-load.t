#!perl

use Test::More tests => 2;

BEGIN {
	use_ok( 'Padre::Plugin::HTML' );
	use_ok( 'Padre::Plugin::HTML::Document' );
}

diag( "Testing Padre::Plugin::HTML $Padre::Plugin::HTML::VERSION, Perl $], $^X" );
