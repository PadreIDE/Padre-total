#!/usr/bin/env perl

use v5.10;
use strict;
use warnings;
# Turn on $OUTPUT_AUTOFLUSH
$| = 1;

use Test::More;
use Test::Deep;

plan( tests => 13 );

use_ok ('t::lib::Debugger');

my ( $dir, $pid ) = start_script('t/eg/05-io.pl');
my $path = $dir;
if ( $^O =~ /Win32/i ) {
	require Win32;
	$path = Win32::GetLongPathName($dir);
}


# diag("Path '$path' Pid '$pid'");

# Patch for Debug::Client ticket #831 (MJGARDNER)
# Turn off ReadLine ornaments
local $ENV{PERL_RL} = ' ornaments=0';

my $debugger = start_debugger();

{
	my $out = $debugger->get;

	like( $out, qr/Loading DB routines from perl5db.pl version/, 'loading line' );
	like( $out, qr{main::\(t/eg/05-io.pl:4\):\s*\$\| = 1;},      'line 4' );
}
# diag("Info: Perl version '$]'");
# diag("Info: Perl version '$^V'");
my $prefix = ( substr( $], 0, 5 ) eq '5.008006' ) ? "Default die handler restored.\n" : '';
# diag("prefix: $prefix");

# see relevant fail report here:
# http://www.nntp.perl.org/group/perl.cpan.testers/2009/12/msg6486949.html
# http://www.nntp.perl.org/group/perl.cpan.testers/2009/12/msg6481372.html

{
	my @out = $debugger->step_in;
	cmp_deeply( \@out, [ 'main::', 't/eg/05-io.pl', 6, 'print "One\n";' ], 'line 6' )
		or diag( $debugger->buffer );
}

{
	my @out = $debugger->step_in;
	cmp_deeply( \@out, [ 'main::', 't/eg/05-io.pl', 7, 'print STDERR "Two\n";' ], 'line 7' )
		or diag( $debugger->buffer );
}

{
	my $out = slurp("$path/out");
	# diag("output: $out");
	is( $out, "One\n", 'STDOUT has One' );
	my $err = slurp("$path/err");
	# diag("error: $err");
	# is( $err, 'STDERR is empty' );
	is( $err, "${prefix}", 'STDERR is empty' );
}

{
	my @out = $debugger->step_in;
	cmp_deeply( \@out, [ 'main::', 't/eg/05-io.pl', 8, 'print "Three\n";' ], 'line 8' )
		or diag( $debugger->buffer );
}

{
	my $out = slurp("$path/out");
	# diag("output: $out");
	is( $out, "One\n", 'STDOUT has One' );
	my $err = slurp("$path/err");
	# diag("error: $err");
	# is( $err, "Two\n", 'STDERR has Two' );
	is( $err, "${prefix}Two\n", 'STDERR has Two' );
}

{
	my @out = $debugger->step_in;
	cmp_deeply( \@out, [ 'main::', 't/eg/05-io.pl', 9, 'print "Four";' ], 'line 9' )
		or diag( $debugger->buffer );
}

{
	my $out = slurp("$path/out");
	# diag("output: $out");
	is( $out, "One\nThree\n", 'STDOUT has One Three' );
	my $err = slurp("$path/err");
	# diag("error: $err");
	# is( $err, "Two\n", 'STDERR has Two' );
	is( $err, "${prefix}Two\n", 'STDERR has Two' );
}

$debugger->run;
$debugger->quit;
done_testing( );

1;

__END__
