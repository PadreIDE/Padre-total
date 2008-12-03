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

my @events = (
	{
		delay => 500,
		code  => sub {
			my $main = $ide->wx->main_window;
			$main->setup_editor('t/03-wx.t');
		},
	},
	{
		delay => 2000,
		code  => sub {
			$ide->wx->ExitMainLoop;
			$ide->wx->main_window->Destroy;
		},
	},
);

foreach my $event (@events) {
	my $id    = Wx::NewId();
	my $timer = Wx::Timer->new( $frame, $id );
	Wx::Event::EVT_TIMER(
		$frame,
		$id,
		$event->{code}
	);
	$timer->Start( $event->{delay}, 1 );
}

$ide->wx->MainLoop;
ok(1);
