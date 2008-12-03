#!/usr/bin/perl

use strict;
use warnings;

use File::Copy            qw(copy);
use File::Spec::Functions qw(catfile);
use Test::NeedsDisplay;
our $tests;
use Test::More;
use Test::Builder;
use t::lib::Padre;
use Padre;

plan tests => $tests;
diag "PADRE_HOME: $ENV{PADRE_HOME}";
my $home = $ENV{PADRE_HOME};
copy catfile('eg', 'hello_world.pl'), catfile($home, 'hello_world.pl');

my $ide   = Padre->ide;
my $frame = $ide->wx->main_window;

my @events = (
	{
		delay => 100,
		code  => sub {
			my $main = $ide->wx->main_window;
			$main->setup_editors( catfile($home, 'hello_world.pl') );
		},
	},
	{
		delay => 200,
		code  => sub {
			my $main = $ide->wx->main_window;
			my $doc  = $main->selected_document;
			my $editor = $doc->editor;
			$editor->SetSelection(10, 15);
			my $T = Test::Builder->new;
			$T->is_eq($editor->GetSelectedText, '/perl', 'selection');
			$T->is_eq($main->selected_text,     '/perl', 'selected_text');
			BEGIN { $main::tests += 2; }
			#$editor->GetText
			#$main->on_save;
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

ok(1, 'finished');
BEGIN { $tests += 1; }



