use strict;
use warnings;

use t::lib::Debugger;

my ( $dir, $pid ) = start_script('t/eg/02-sub.pl');

require Test::More;
import Test::More;
require Test::Deep;
import Test::Deep;

plan( tests => 14 );

my $debugger = start_debugger();

{
	my $out = $debugger->get;

	# Loading DB routines from perl5db.pl version 1.28
	# Editor support available.
	#
	# Enter h or `h h' for help, or `man perldebug' for more help.
	#
	# main::(t/eg/01-add.pl:4):	$| = 1;
	#   DB<1>

	like( $out, qr/Loading DB routines from perl5db.pl version/, 'loading line' );
	like( $out, qr{main::\(t/eg/02-sub.pl:4\):\s*\$\| = 1;},     'line 4' );
}

{
	my @out = $debugger->step_in;
	cmp_deeply( \@out, [ 'main::', 't/eg/02-sub.pl', 6, 'my $x = 11;' ], 'line 6' )
		or diag( $debugger->buffer );
}
{
	my @out = $debugger->step_in;
	cmp_deeply( \@out, [ 'main::', 't/eg/02-sub.pl', 7, 'my $y = 22;' ], 'line 7' )
		or diag( $debugger->buffer );
}

{
	my @out = $debugger->step_in;
	cmp_deeply( \@out, [ 'main::', 't/eg/02-sub.pl', 8, 'my $q = f($x, $y);' ], 'line 8' )
		or diag( $debugger->buffer );
}

{
	my @out = $debugger->step_over;
	cmp_deeply( \@out, [ 'main::', 't/eg/02-sub.pl', 9, 'my $z = $x + $y;' ], 'line 9' )
		or diag( $debugger->buffer );
}
SKIP: {
    skip( 'user has .perldb file, skipping...', 1 ) if rc_file;

	my @out = $debugger->get_value('$q');
	cmp_deeply( \@out, [242], '$q is 11*22=242' )
		or diag( $debugger->buffer );
}
{
	my @out = $debugger->get_value('$z');
	cmp_deeply( \@out, [''], '$z is empty' );
}


{
	my $out = $debugger->step_over;
	ok( $out =~ s/DB<\d+> $/DB<> /, 'replace number as it can be different on other versions of perl' );
	is( $out, "main::(t/eg/02-sub.pl:10):\tmy \$t = f(19, 23);\n  DB<> ", 'step over on simple statement' );
}

{
	my $out = $debugger->step_over;
	ok( $out =~ s/DB<\d+> $/DB<> /, 'replace number as it can be different on other versions of perl' );
	is( $out, "main::(t/eg/02-sub.pl:11):\t\$t++;\n  DB<> ", 'step over in scalar context' );
}

{
	my @out = $debugger->step_over;
	cmp_deeply( \@out, [ 'main::', 't/eg/02-sub.pl', 12, '$z++;' ], 'line 12' )
		or diag( $debugger->buffer );
}

{

	# Debugged program terminated.  Use q to quit or R to restart,
	#   use o inhibit_exit to avoid stopping after program termination,
	#   h q, h R or h o to get additional info.
	#   DB<1>
	my $out = $debugger->step_in;
	like( $out, qr/Debugged program terminated/ );
}

{
	$debugger->quit;
}