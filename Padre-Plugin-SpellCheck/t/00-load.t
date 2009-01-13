#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Padre::Plugin::SpellCheck' );
}

diag( "Testing Padre::Plugin::SpellCheck $Padre::Plugin::SpellCheck::VERSION, Perl $], $^X" );
