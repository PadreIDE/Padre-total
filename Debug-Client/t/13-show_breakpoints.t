#!/usr/bin/perl

use strict;
use warnings;

# Turn on $OUTPUT_AUTOFLUSH
$| = 1;

use t::lib::Debugger;

my ( $dir, $pid ) = start_script('t/eg/03-return.pl');

require Test::More;
import Test::More;
require Test::Deep;
import Test::Deep;

plan( tests => 7 );

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
	like( $out, qr{main::\(t/eg/03-return.pl:4\):\s*\$\| = 1;},  'line 4' );
}

{
	my @out = $debugger->step_in;
	cmp_deeply( \@out, [ 'main::', 't/eg/03-return.pl', 6, 'my $x = 11;' ], 'line 6' )
		or diag( $debugger->buffer );
}

{
	ok( $debugger->set_breakpoint( 't/eg/03-return.pl', 'g' ), 'set_breakpoint' );
}

{
	ok( $debugger->show_breakpoints( ) =~ m{t/eg/03-return.pl:}, 'show_breakpoints' );
}

{
	my @out = $debugger->run;
	cmp_deeply( \@out, [ 'main::g', 't/eg/03-return.pl', 22, q{   my (@in) = @_;} ], 'line 9' )
		or diag( $debugger->buffer );
}


{

	# Debugged program terminated.  Use q to quit or R to restart,
	#   use o inhibit_exit to avoid stopping after program termination,
	#   h q, h R or h o to get additional info.
	#   DB<1>
	my $out = $debugger->run;
	like( $out, qr/Debugged program terminated/ );
}

{
	$debugger->quit;
}

done_testing( );

1;

__END__