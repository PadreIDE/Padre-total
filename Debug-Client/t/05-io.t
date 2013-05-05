use strict;
use warnings FATAL => 'all';

use English qw( -no_match_vars );
local $OUTPUT_AUTOFLUSH = 1;
#use Data::Printer { caller_info => 1, colored => 1, };

use Test::More tests => 14;
use Test::Deep;
use t::lib::Debugger;

BEGIN {
	use_ok( 'Term::ReadKey', '2.30' );
	use_ok( 'Term::ReadLine', '1.10' );
	if ( $^O eq 'MSWin32'){
		use_ok( 'Term::ReadLine::Perl', '1.0303' );
	} else {
		use_ok( 'Term::ReadLine::Gnu', '1.2' );
	}
}

diag "\nmk1 \n";
diag "env->columns - $ENV{COLUMNS}\n" if defined $ENV{COLUMNS};
diag "env->lines - $ENV{LINES}\n" if defined $ENV{LINES};
diag "env->term - $ENV{TERM}\n" if defined $ENV{TERM};
diag "env->perl-rl - $ENV{PERL_RL}\n" if defined $ENV{PERL_RL};
diag "mk2 \n";

my $term = Term::ReadLine->new('none');
diag $term->ReadLine;
diag "mk2a \n";
my ( $dir, $pid ) = start_script('t/eg/05-io.pl');
my $path = $dir;
diag "mk2b \n";
if ( $OSNAME  =~ /Win32/i ) {
	require Win32;
	$path = Win32::GetLongPathName($dir);
}
diag "mk2c \n";
# Patch for Debug::Client ticket #831 (MJGARDNER)
# Turn off ReadLine ornaments
##local $ENV{PERL_RL} = ' ornaments=0';
$ENV{TERM} = 'dumb' if ! exists $ENV{TERM};
diag "env->term - $ENV{TERM}\n" if defined $ENV{TERM};
diag "mk3 \n";
#sleep 1;
my $debugger = t::lib::Debugger::start_debugger();
diag "mk4 \n";

SCOPE:{
	my $out = $debugger->get;

	like( $out, qr/Loading DB routines from perl5db.pl version/, 'loading line' );
	like( $out, qr{main::\(t/eg/05-io.pl:4\):\s*\$\| = 1;},      'line 4' );
}
# diag("Info: Perl version '$]'"); old
# diag("Info: Perl version '$^V'"); new
my $prefix = ( substr( $] , 0, 5 ) eq '5.008006' ) ? "Default die handler restored.\n" : '';
# diag("prefix: $prefix");

# see relevant fail report here:
# http://www.nntp.perl.org/group/perl.cpan.testers/2009/12/msg6486949.html
# http://www.nntp.perl.org/group/perl.cpan.testers/2009/12/msg6481372.html

{
	my @out = $debugger->step_in;
	# cmp_deeply( \@out, [ 'main::', 't/eg/05-io.pl', 6, 'print "One\n";' ], 'line 6' )
		# or diag( $debugger->buffer );
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

done_testing();

__END__
