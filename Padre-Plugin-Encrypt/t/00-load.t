#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Padre::Plugin::Encrypt' );
}

diag( "Testing Padre::Plugin::Encrypt $Padre::Plugin::Encrypt::VERSION, Perl $], $^X" );
