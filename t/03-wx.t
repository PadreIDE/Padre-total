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
use Padre::Wx;

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

			$editor->ReplaceSelection('/java');
			$editor->SetSelection(0, 0);
			# TODO: search
			$T->is_eq($main->selected_text,     '', 'selected_text');

			BEGIN { $main::tests += 3; }
		}
	},
	{
		delay => 1500,
		code  => sub {
			my $T = Test::Builder->new;
			my $main = $ide->wx->main_window;
			$main->on_save;
			if ( open my $fh, '<', catfile($home, 'hello_world.pl') ) {
				my $line = <$fh>;
				$T->is_eq($line, "#!/usr/bin/java\n", 'file really changed');
			}

			BEGIN { $main::tests += 1; }
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

t::lib::Padre::setup_events($frame, \@events);


$ide->wx->MainLoop;

ok(1, 'finished');
BEGIN { $tests += 1; }



