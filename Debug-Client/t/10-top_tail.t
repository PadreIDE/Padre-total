#!/usr/bin/perl

use strictures 1;

# Turn on $OUTPUT_AUTOFLUSH
local $| = 1;

use Test::More;
use Test::Deep;
plan( tests => 7 );

use_ok( 'PadWalker', '1.92' );

use_ok('t::lib::Debugger');

ok( start_script('t/eg/14-y_zero.pl'), 'start script' );

my $debugger;
ok( $debugger = start_debugger(), 'start debugger' );

ok( $debugger->get, 'get debugger' );

like( $debugger->run, qr/Debugged program terminated/, 'Debugged program terminated' );

like( $debugger->quit, qr/1/, 'debugger quit' );

done_testing();

1;

__END__
