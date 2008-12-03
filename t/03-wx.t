#!/usr/bin/perl

use strict;
use warnings;
use Test::NeedsDisplay;
use File::Temp qw(tempdir);
use Test::More tests => 1;
use t::lib::Padre;
use Padre;

my $ide   = Padre->ide;
my $frame = $ide->wx->main_window;


my $exit_id = Wx::NewId();
my $timer_exit = Wx::Timer->new( $frame, $exit_id );
Wx::Event::EVT_TIMER(
	$frame,
	$exit_id,
	sub {
		$ide->wx->ExitMainLoop;
		$ide->wx->main_window->Destroy;
	}
);

my $open_id = Wx::NewId();
my $timer_open = Wx::Timer->new( $frame, $open_id );
Wx::Event::EVT_TIMER(
	$frame,
	$open_id,
	sub {
		my $main = $ide->wx->main_window;
		$main->setup_editor('t/03-wx.t');
	}
);

$timer_open->Start( 500, 1 );
$timer_exit->Start( 2000, 1 );

$ide->wx->MainLoop;
ok(1);
