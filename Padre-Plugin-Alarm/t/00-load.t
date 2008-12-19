#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Padre::Plugin::Alarm' );
}

diag( "Testing Padre::Plugin::Alarm $Padre::Plugin::Alarm::VERSION, Perl $], $^X" );
