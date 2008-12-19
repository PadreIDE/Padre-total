#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Padre::Plugin::AcmePlayCode' );
}

diag( "Testing Padre::Plugin::AcmePlayCode $Padre::Plugin::AcmePlayCode::VERSION, Perl $], $^X" );
