#!perl

use Test::More tests => 1;

BEGIN {
	use_ok( 'Padre::Plugin::LaTeX' );
}

diag( "Testing Padre::Plugin::LaTeX $Padre::Plugin::LaTeX::VERSION, Perl $], $^X" );
