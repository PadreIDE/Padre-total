#!perl

use Test::More tests => 1;

BEGIN {
	use_ok('Padre::Plugin::IntelliPerl');
}

diag("Testing Padre::Plugin::IntelliPerl $Padre::Plugin::IntelliPerl::VERSION, Perl $], $^X");
