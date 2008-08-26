#!/usr/bin/perl

use strict;
use warnings;
use File::Temp qw(tempdir);
use Test::More tests => 1;
use t::lib::Padre;
use Padre;

my $ide   = Padre->ide;
my $frame = $ide->wx->main_window;

my $timer = Wx::Timer->new( $frame );
Wx::Event::EVT_TIMER(
	$frame,
	-1,
	sub {
        	$ide->wx->ExitMainLoop;
		$ide->wx->main_window->Destroy;
	}
);
$timer->Start( 500, 1 );
$ide->wx->MainLoop;
ok(1);
