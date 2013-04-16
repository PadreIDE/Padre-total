#!/usr/bin/perl

use 5.010;
use strict;
use warnings FATAL => 'all';   

# Turn on $OUTPUT_AUTOFLUSH
local $| = 1;

use Test::More tests => 4;
use Test::Deep;
use PadWalker;
use t::lib::Debugger;

start_script('t/eg/14-y_zero.pl');

my $debugger;
ok( $debugger = start_debugger(), 'start debugger' );

ok( $debugger->get, 'get debugger' );

like( $debugger->run, qr/Debugged program terminated/, 'Debugged program terminated' );

like( $debugger->quit, qr/1/, 'debugger quit' );
