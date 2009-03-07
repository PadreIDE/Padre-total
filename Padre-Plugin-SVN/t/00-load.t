#!perl

use Test::More tests => 1;

BEGIN {
	use_ok( 'Padre::Plugin::SVN' );
}

diag( "Testing Padre::Plugin::SVN $Padre::Plugin::SVN::VERSION, Perl $], $^X" );
