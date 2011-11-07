#!/usr/bin/env perl

use strict;
use warnings;

# Turn on $OUTPUT_AUTOFLUSH
$| = 1;

use t::lib::Debugger;

# Testing step_in (s) and show_line (.) on a simple script

my ( $dir, $pid ) = start_script('t/eg/01-add.pl');

require Test::More;
import Test::More;
require Test::Deep;
import Test::Deep;

plan( tests => 9 );

diag("PID $pid");
my $debugger = start_debugger();
isa_ok( $debugger, 'Debug::Client' );


{
	my $out = $debugger->get;

	# Loading DB routines from perl5db.pl version 1.28
	# Editor support available.
	#
	# Enter h or `h h' for help, or `man perldebug' for more help.
	#
	# main::(t/eg/01-add.pl:4):	$| = 1;
	#   DB<1>

	# Loading DB routines from perl5db.pl version 1.32
	# Editor support available.
	#
	# Enter h or `h h' for help, or `man perldebug' for more help.
	#
	# main::(01-add.pl:4):	$| = 1;
	#   DB<1>

	# Loading DB routines from perl5db.pl version 1.33
	# Editor support available.
	#
	# Enter h or `h h' for help, or `man perldebug' for more help.
	#
	# main::(01-add.pl:4):	$| = 1;
	#	DB<1>

	like( $out, qr{Loading DB routines from perl5db.pl version}, 'loading line' );
	like( $out, qr{main::\(t/eg/01-add.pl:4\):\s*\$\| = 1;},     'line 4' );
}


{
	my @out = $debugger->step_in;
	diag("@out");
	cmp_deeply( \@out, [ 'main::', 't/eg/01-add.pl', 6, 'my $x = 1;' ], 'line 6' )
		or diag( $debugger->buffer );
}

{
	my $out = $debugger->step_in;
	ok( $out =~ s/DB<\d+> $/DB<> /, 'replace number as it can be different on other versions of perl' );
	is( $out, "main::(t/eg/01-add.pl:7):\tmy \$y = 2;\n  DB<> ", 'line 7' ) or do {
		$out =~ s/ /S/g;
		diag($out);
		}
}

{
	my @out = $debugger->show_line;
	cmp_deeply( \@out, [ 'main::', 't/eg/01-add.pl', 7, 'my $y = 2;' ], 'line 7' )
		or diag( $debugger->buffer );
}
{
	my @out = $debugger->step_in;
	cmp_deeply( \@out, [ 'main::', 't/eg/01-add.pl', 8, 'my $z = $x + $y;' ], 'line 8' )
		or diag( $debugger->buffer );
}

{
	my $out = $debugger->quit;
	like( $out, qr/1/, 'debugger quit' );
}

done_testing( );

1;

__END__
