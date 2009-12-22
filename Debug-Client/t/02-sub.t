use strict;
use warnings;

use t::lib::Debugger;

my ( $dir, $pid ) = start_script('t/eg/02-sub.pl');

require Test::More;
import Test::More;
require Test::Deep;
import Test::Deep;

plan( tests => 26 );

my $debugger = start_debugger();

{
	my @out = $debugger->get;
	cmp_deeply( \@out, [ 'main::', 't/eg/02-sub.pl', 4, '$| = 1;' ], 'line 4' )
		or diag( $debugger->buffer );
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
	my @out = $debugger->step_in;
	cmp_deeply( \@out, [ 'main::f', 't/eg/02-sub.pl', 16, '   my ($q, $w) = @_;' ], 'line 16' )
		or diag( $debugger->buffer );
}

{
	my @out = $debugger->step_in;
	cmp_deeply( \@out, [ 'main::f', 't/eg/02-sub.pl', 17, '   my $multi = $q * $w;' ], 'line 17' )
		or diag( $debugger->buffer );
}

{
	my @out = $debugger->step_in;
	cmp_deeply( \@out, [ 'main::f', 't/eg/02-sub.pl', 18, '   my $add   = $q + $w;' ], 'line 18' )
		or diag( $debugger->buffer );
}

{
	my @out = $debugger->step_in;
	cmp_deeply( \@out, [ 'main::f', 't/eg/02-sub.pl', 19, '   return $multi;' ], 'line 19' )
		or diag( $debugger->buffer );
}

{
	my @out = $debugger->step_in;
	cmp_deeply( \@out, [ 'main::', 't/eg/02-sub.pl', 9, 'my $z = $x + $y;' ], 'line 9' )
		or diag( $debugger->buffer );
}

{
	my @out = $debugger->get_value('$q');
	cmp_deeply( \@out, [242], '$q is 11*22=242' )
		or diag( $debugger->buffer );
}
{
	my @out = $debugger->get_value('$z');
	cmp_deeply( \@out, [''], '$z is empty' )
		or diag( $debugger->buffer );
}

{
	my $out = $debugger->step_in;
	ok( $out =~ s/DB<\d+> $/DB<> /, 'replace number as it can be different on other versions of perl' );
	is( $out, "main::(t/eg/02-sub.pl:10):\tmy \$t = f(19, 23);\n  DB<> ", 'out' );
}

{
	my $out = $debugger->step_in;
	ok( $out =~ s/DB<\d+> $/DB<> /, 'replace number as it can be different on other versions of perl' );
	is( $out, "main::f(t/eg/02-sub.pl:16):\t   my (\$q, \$w) = \@_;\n  DB<> ", 'out' );
}

{
	my $out = $debugger->step_in;
	ok( $out =~ s/DB<\d+> $/DB<> /, 'replace number as it can be different on other versions of perl' );
	is( $out, "main::f(t/eg/02-sub.pl:17):\t   my \$multi = \$q * \$w;\n  DB<> ", 'out' );
}

{
	my $out = $debugger->step_in;
	ok( $out =~ s/DB<\d+> $/DB<> /, 'replace number as it can be different on other versions of perl' );
	is( $out, "main::f(t/eg/02-sub.pl:18):\t   my \$add   = \$q + \$w;\n  DB<> ", 'out' );
}


{
	my $out = $debugger->step_in;
	ok( $out =~ s/DB<\d+> $/DB<> /, 'replace number as it can be different on other versions of perl' );
	is( $out, "main::f(t/eg/02-sub.pl:19):\t   return \$multi;\n  DB<> ", 'out' );
}

{
	my $out = $debugger->step_in;
	ok( $out =~ s/DB<\d+> $/DB<> /, 'replace number as it can be different on other versions of perl' );
	is( $out, "main::(t/eg/02-sub.pl:11):\t\$t++;\n  DB<> ", 'out' );
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
	like( $out, qr/Debugged program terminated/ );
}

{
	$debugger->quit;
}
