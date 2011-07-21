use strict;
use warnings;

use t::lib::Debugger;

# Testing step_in (s) and step_out (r)

my ( $dir, $pid ) = start_script('t/eg/02-sub.pl');

require Test::More;
import Test::More;
require Test::Deep;
import Test::Deep;

plan( tests => 19 );

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
	cmp_deeply( \@out, [ 'main::', 't/eg/02-sub.pl', 6, 'my $x = 11;' ], 'line 6' );
}
{
	my @out = $debugger->step_in;
	cmp_deeply( \@out, [ 'main::', 't/eg/02-sub.pl', 7, 'my $y = 22;' ], 'line 7' );
}

{
	my @out = $debugger->step_in;
	cmp_deeply( \@out, [ 'main::', 't/eg/02-sub.pl', 8, 'my $q = f($x, $y);' ], 'line 8' );
}

{
	my @out = $debugger->step_in;
	cmp_deeply( \@out, [ 'main::f', 't/eg/02-sub.pl', 16, '   my ($q, $w) = @_;' ], 'line 16' );
}

{
	my @out = $debugger->step_in;
	cmp_deeply( \@out, [ 'main::f', 't/eg/02-sub.pl', 17, '   my $multi = $q * $w;' ], 'line 17' )
		or diag( $debugger->buffer );
}

{
	my @out = $debugger->step_out;
	cmp_deeply( \@out, [ 'main::', 't/eg/02-sub.pl', 9, 'my $z = $x + $y;', 242 ], 'line 9' )
		or diag( $debugger->buffer );
}

SKIP: {
    skip( 'user has .perldb file, skipping...', 1) if rc_file;

	my @out = $debugger->get_value('$q');
	cmp_deeply( \@out, [242], '$q is 11*22=242' );
}
{
	my @out = $debugger->get_value('$z');
	cmp_deeply( \@out, [''], '$z is empty' );
}

{
	my $out = $debugger->step_in;
	ok( $out =~ s/DB<\d+> $/DB<> /, 'replace number as it can be different on other versions of perl' );
	is( $out, "main::(t/eg/02-sub.pl:10):\tmy \$t = f(19, 23);\n  DB<> ", 'out' );
}

{
	my @out = $debugger->step_in;
	cmp_deeply( \@out, [ 'main::f', 't/eg/02-sub.pl', 16, '   my ($q, $w) = @_;' ], 'line 17' )
		or diag( $debugger->buffer );
}

{
	my $out = $debugger->step_in;
	ok( $out =~ s/DB<\d+> $/DB<> /, 'replace number as it can be different on other versions of perl' );
	is( $out, "main::f(t/eg/02-sub.pl:17):\t   my \$multi = \$q * \$w;\n  DB<> ", 'out' );
}

{
	my @out = $debugger->step_out;
	cmp_deeply( \@out, [ 'main::', 't/eg/02-sub.pl', 11, '$t++;', 437 ], 'out' );
}

{
	my $out = $debugger->step_in;
	ok( $out =~ s/DB<\d+> $/DB<> /, 'replace number as it can be different on other versions of perl' );
	is( $out, "main::(t/eg/02-sub.pl:12):\t\$z++;\n  DB<> ", 'out' );
}

{

	# Debugged program terminated.  Use q to quit or R to restart,
	#   use o inhibit_exit to avoid stopping after program termination,
	#   h q, h R or h o to get additional info.
	#   DB<1>
	my $out = $debugger->step_in;
	like( $out, qr/Debugged program terminated/, 'terminated' );
}

{
	$debugger->quit;
}
