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

plan( tests => 11 );

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
	ok( ( $debugger->get_options() =~ m\CommandSet = 580\g ), 'get_options() CommandSet = 580' );
}

{
	ok( $debugger->set_breakpoint( 't/eg/14-y_zero.pl', '14' ), 'set_breakpoint' );
}
{
	my $out = $debugger->set_option('frame=2');	
	like( $out, qr{frame = '2'},  'set_option' );
}
{
	my @out = $debugger->run;	
	cmp_deeply( \@out, ['main::', 't/eg/14-y_zero.pl', '14', 'print "$_ : $line \n";', ], 'line 14' )
		or diag( @out );
}
{
	my $out = $debugger->set_option('frame=0');	
	like( $out, qr{frame = '0'},  'set_option' );
}
{
	like( $debugger->module(), qr{main::}, 'get module name' ) or diag( $debugger->module() );
}

{
	like( $debugger->list_subroutine_names(), qr{Term::ReadLine}, 'S module' )or diag( $debugger->list_subroutine_names() );
}

{
	like( $debugger->list_subroutine_names('strict'), qr{strict}, 'S module plus regex' )or diag( $debugger->list_subroutine_names() );
}

{
	$debugger->quit;
}

done_testing( );

1;

__END__