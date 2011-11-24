#!/usr/bin/env perl

use strict;
use warnings;

# Turn on $OUTPUT_AUTOFLUSH
$| = 1;

use t::lib::Debugger;
my ( $dir, $pid ) = start_script('t/eg/14-y_zero.pl');

require Test::More;
import Test::More;
require Test::Deep;
import Test::Deep;

plan( tests => 18 );

use_ok( 'PadWalker', '1.92' );

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
	like( $out, qr{main::(14-y_zero.pl:8):	$| = 1;},  'line 8' );
}

{
	ok( $debugger->toggle_trace =~ m/Trace = on/, 'Trace on' );
}

{
	ok( $debugger->set_breakpoint( 't/eg/14-y_zero.pl', '14' ), 'set_breakpoint' );
}

{
	ok( $debugger->show_breakpoints() =~ m/14-y_zero.pl:/, 'show_breakpoints' );
}

{
	my @out = $debugger->run;
	cmp_deeply( \@out, ['main::', 't/eg/14-y_zero.pl', '14', ' print "$_ : $line \n";', ], 'line 14' )
		or diag( $debugger->buffer );
}

{
	my @out = $debugger->get_y_zero();
	cmp_deeply( \@out, [ '$line = 0' ], 'y_0 $line = 0' )
		or diag( $debugger->buffer );
}

{
	ok( $debugger->toggle_trace =~ m/Trace = off/, 'Trace off' );
}

{
	foreach (1..3) {
	$debugger->run();
	my @out = $debugger->get_y_zero();
	cmp_deeply( \@out, [ "\$line = $_" ], "y_0 \$line = $_" )
		or diag( $debugger->buffer );
	my $out = $debugger->get_value();
	ok( $out == $_ , "\$_ = $out" );
	}
}

{
	my $out = $debugger->__send( 'p 2 + 3' );
	ok( $out == 5, '__send' );	
}
{
	my $out = $debugger->__send_np( 'p 2 + 3' );
	like( $out, qr/[5]/, '__send_np' );	
}
{

	# Debugged program terminated.  Use q to quit or R to restart,
	#   use o inhibit_exit to avoid stopping after program termination,
	#   h q, h R or h o to get additional info.
	#   DB<1>
	my $out = $debugger->run;
	like( $out, qr/Debugged program terminated/, 'debugger terminated' );
}

{
	$debugger->quit;
}

done_testing( );

1;

__END__