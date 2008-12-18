#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Padre::Plugin::XML' );
}

diag( "Testing Padre::Plugin::XML $Padre::Plugin::XML::VERSION, Perl $], $^X" );
