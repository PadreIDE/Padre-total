#!perl

use Test::More tests => 2;

BEGIN {
	use_ok( 'Padre::Plugin::XML' );
	use_ok( 'Padre::Task::SyntaxChecker::XML' );
}

diag( "Testing Padre::Plugin::XML $Padre::Plugin::XML::VERSION, Perl $], $^X" );
my $task = Padre::Task::SyntaxChecker::XML->new();
