#!/usr/bin/perl

use strict;
use warnings;

use File::Basename        qw(basename);
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
copy catfile('eg', 'hello_world.pl'),    catfile($home, 'hello_world.pl');
copy catfile('eg', 'cyrillic_test.pl'),  catfile($home, 'cyrillic_test.pl');

my $ide   = Padre->ide;
my $frame = $ide->wx->main_window;

my @events = (
	{
		delay => 100,
		code  => sub {
			my $main = $ide->wx->main_window;
			my $T = Test::Builder->new;
			{
				my @editors = $main->pages;
				$T->is_num(scalar(@editors), 1, '1 editor');
			}
			$main->setup_editors( catfile($home, 'hello_world.pl') );
			{
				my @editors = $main->pages;
				#$T->todo_skip('close the empty buffer');
				$T->is_num(scalar(@editors), 1, '1 editor');
			}
			BEGIN { $main::tests += 2; }
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
			$T->is_eq($main->selected_text,     '', 'selected_text');

			Padre::Wx::Dialog::Find->search( search_term => qr/java/ );
			my ($start, $end) = $editor->GetSelection;
			$T->is_num($start, 11, 'start is 11');
			$T->is_num($end,   15, 'end is 15');
			
			$T->is_eq($main->selected_text,     'java', 'selected_text');

			$main->on_save;
			if ( open my $fh, '<', catfile($home, 'hello_world.pl') ) {
				my $line = <$fh>;
				$T->is_eq($line, "#!/usr/bin/java\n", 'file really changed');
			}

			BEGIN { $main::tests += 7; }
		}
	},
	{
		delay => 300,
		code  => sub {
			my $main = $ide->wx->main_window;
			$main->setup_editors( catfile($home, 'cyrillic_test.pl') );

			my $T = Test::Builder->new;
			my $doc  = $main->selected_document;
			my $editor = $doc->editor;

			{
				my @editors = $main->pages;
				$T->is_num(scalar(@editors), 2, '2 editors');
			}

			{
				Padre::Wx::Dialog::Find->search( search_term => qr/test/ );
				$T->is_eq($main->selected_text,    'test', 'selected_text');
				my ($start, $end) = $editor->GetSelection;
				$T->is_num($start, 56, 'start is 56');
				$T->is_num($end,   60, 'end is 60');
			}
			{
				Padre::Wx::Dialog::Find->search( search_term => qr/test/ );
				$T->is_eq($main->selected_text,    'test', 'selected_text');
				my ($start, $end) = $editor->GetSelection;
				$T->is_num($start, 211, 'start is 211');
				$T->is_num($end,   215, 'end is 215');
			}

			$main->on_close_all_but_current;
			{
				my @editors = $main->pages;
				$T->is_num(scalar(@editors), 1, '1 editor');
				my $doc = $main->selected_document;
				$T->is_eq(basename($doc->filename), 'cyrillic_test.pl', 'filename');
			}

			BEGIN { $main::tests += 9; }
		},
	},
	{
		delay => 4000,
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



