#!/usr/bin/env perl


use strictures 1;

# Turn on $OUTPUT_AUTOFLUSH
local $| = 1;

use Test::More;
use Test::Deep;
plan( tests => 8 );


#Top
use t::lib::Debugger;

start_script('t/eg/test_1415.pl');
my $debugger;
$debugger = start_debugger();
$debugger->get;


#Body
$debugger->__send( 'w' . '@fonts' );

# diag( $debugger->__send('L w') );
like( $debugger->__send('L w'), qr/fonts/, 'set watchpoints for @fonts' );

#this is 'unlike' as it's a side affect of using a wantarry
unlike( my @list = $debugger->run, qr/Watchpoint/, 'Watchpoint value changed' );

like( $debugger->get_buffer, qr/fonts changed/, 'check buffer' );
unlike( $debugger->module, qr/TERMINATED/, 'module still alive' );

$debugger->get_lineinfo;
like( $debugger->get_filename, qr/test_1415/, 'check where we are filename' );
is( $debugger->get_row, 19, 'check where we are row' );
like( $debugger->get_stack_trace(), qr/ANON/, 'O look, we are in an ANON sub' );

#ToDo need a test for the value of @fonts
# like( $debugger->get_value('@fonts'), qr/fred/, 'view contents of @fonts');
# $debugger->get_value("@fonts");
# diag( $debugger->get_buffer );
# cmp_deeply( \@out, [ 'main::', 't/eg/02-sub.pl', 7, 'my $y = 22;' ], 'view contents of @fonts' );

like( $debugger->run, qr/Watchpoint/, 'stoped for watchpoint' );


#Tail
$debugger->quit;
done_testing();

1;

__END__
