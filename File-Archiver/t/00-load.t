#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'File::Archiver' );
}

diag( "Testing File::Archiver $File::Archiver::VERSION, Perl $], $^X" );


my $a = File::Archiver->new;
isa_ok($a, 'File::Archiver');