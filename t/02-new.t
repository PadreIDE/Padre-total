#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Exception;
use Test::NoWarnings;
my $tests;
plan tests => $tests + 1;

use File::Temp   qw(tempdir);
use Data::Dumper qw(Dumper);

use t::lib::Padre;
use Padre;

my $app = Padre->new;

diag "Wx Version: $Wx::VERSION " . Wx::wxVERSION_STRING();

SCOPE: {
    isa_ok($app, 'Padre');
    ok ! $app->get_index, 'no index';
    my @files = $app->get_files;
    is_deeply \@files, [], 'no files';

    BEGIN { $tests += 3; }
}

SCOPE: {
    my $same = Padre->new;
    isa_ok($same, 'Padre');
    is $same, $app, 'Same';

    BEGIN { $tests += 2; }
}


SCOPE: {
    my $config = $app->get_config;
    is_deeply {
            DISPLAY_MIN_LIMIT => 2,
            DISPLAY_MAX_LIMIT => 200,
            show_line_numbers => 0,
            show_eol          => 0,
            search_terms      => [],
            replace_terms     => [],
            command_line      => '',
            startup           => 'new',
            projects          => {},
            save_on_run       => 'same',
            current_project   => '',
            editor            => {
                    tab_size      => 8,
            },
            main              => {
                top       => -1,
                left      => -1,
                width     => -1,
                height    => -1,
                maximized => 0,
            },
        }, $config,
        'defaults';

    BEGIN { $tests += 1; }
}

SCOPE: {
    throws_ok {$app->get_recent('xyz')} qr/Invalid type 'xyz'/, 'invalid get_recent';
    throws_ok {$app->get_recent()} qr/No type given/, 'invalid get_recent';
    throws_ok {$app->add_to_recent('xyz', 'Nothing')} qr/Invalid type 'xyz'/, 'invalid add_to_recent';

    my $current = $app->get_current('pod');
    my $current_index = $app->get_current_index('pod');
    ok !defined $current, 'current pod not defined';
    ok !defined $current_index, 'current pod not defined';

    my @pods = $app->get_recent('pod');
    is_deeply \@pods, [], 'no pods yet'
       or diag Dumper \@pods;
    my @files = $app->get_recent('files');
    is_deeply \@files, [], 'no files yet';
    $current_index = $app->get_current_index('pod');
    ok ! defined $current_index, 'current undef';


    ok !$app->add_to_recent('pod', 'Test'), 'set_recent';
    @pods = $app->get_recent('pod');
    is_deeply \@pods, ['Test'], 'pods';
    $current_index = $app->get_current_index('pod');
    is $current_index, 0, 'current 0';
    is $app->get_current('pod'), 'Test', 'current is Test';

    ok !$app->add_to_recent('pod', 'Test::More'), 'set_recent';
    @pods = $app->get_recent('pod');
    is_deeply \@pods, ['Test', 'Test::More'], 'pods';
    is $app->get_current('pod'), 'Test::More', 'current is Test::More';

    is $app->set_item('pod', 0), 'Test', 'set_item';
    is $app->get_current('pod'), 'Test', 'current is Test';

# TODO next, previous,
# TODO limit number of items and see what happens
# TODO whne setting an element that was already in the list as recent
# it should become the last one!

    BEGIN { $tests += 17; }
}

SCOPE: {
    my @words = qw(One Two Three Four Five Six);
    foreach my $name (@words) {
        $app->add_to_recent('pod', $name);
    }
    my @pods = $app->get_recent('pod');
    is_deeply \@pods, ['Test', 'Test::More', @words], 'pods';
    is $app->get_current('pod'), 'Six', 'current is Six';

    is $app->prev_module, 'Five', 'prev Five';
    is $app->prev_module, 'Four', 'prev Four';
    is $app->get_current('pod'), 'Four', 'current is Four';
    is $app->next_module, 'Five', 'next Five';

    BEGIN { $tests += 6; }
}
