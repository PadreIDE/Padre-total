#!perl

use Test::More tests => 1;

BEGIN {
	use_ok( 'Padre::Plugin::Git' );
}

diag( "Testing Padre::Plugin::Git $Padre::Plugin::Git::VERSION, Perl $], $^X" );
