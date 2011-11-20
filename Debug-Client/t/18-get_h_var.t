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

plan( tests => 5 );

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
	ok( $debugger->get_h_var('h') =~ m/Help is currently only available for the new 5.8 command set/g, 'get_h_var(h) -> 5.8 command' );
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