#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Padre::Plugin::VimishLexer' );
}

diag( "Testing Padre::Plugin::VimishLexer $Padre::Plugin::VimishLexer::VERSION, Perl $], $^X" );
