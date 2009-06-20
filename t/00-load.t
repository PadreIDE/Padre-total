#!perl

use Test::More tests => 1;

BEGIN {
	use_ok( 'Padre::Plugin::REPL' );
}

diag( "Testing Padre::Plugin::REPL $Padre::Plugin::REPL::VERSION, Perl $], $^X" );
