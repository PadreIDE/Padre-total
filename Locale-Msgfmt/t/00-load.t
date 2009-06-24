#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Locale::Msgfmt' );
}

diag( "Testing Locale::Msgfmt $Locale::Msgfmt::VERSION, Perl $], $^X" );
