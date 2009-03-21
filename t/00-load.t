#!perl

use Test::More tests => 1;

BEGIN {
	use_ok( 'Padre::Plugin::DataWalker' );
}

diag( "Testing Padre::Plugin::DataWalker $Padre::Plugin::DataWalker::VERSION, Perl $], $^X" );
