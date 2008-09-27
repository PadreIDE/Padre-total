#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 21;
use Test::Exception;
use Test::NoWarnings;

use File::Temp   qw(tempdir);
use Data::Dumper qw(Dumper);

use t::lib::Padre;
use Padre;

my $app = Padre->new;
isa_ok($app, 'Padre');

diag "Wx Version: $Wx::VERSION " . Wx::wxVERSION_STRING();

SCOPE: {
    my $same = Padre->new;
    isa_ok($same, 'Padre');
    is $same, $app, 'Same';
}


SCOPE: {
    my $config = $app->config;
    is_deeply {
            experimental      => 0,
            pod_minlist => 2,
            pod_maxlist => 200,
            editor_linenumbers => 0,
            editor_eol          => 0,
            search_terms      => [],
            replace_terms     => [],
            command_line      => '',
            startup           => 'new',
            projects          => {},
            run_save       => 'same',
            current_project   => '',
            editor            => {
                    tab_size      => 8,
                    show_calltips => 1,
            },
            bookmarks     => {},
            main              => {
                top       => -1,
                left      => -1,
                width     => -1,
                height    => -1,
                maximized => 0,
            },
            plugins => {},
        }, $config,
        'defaults';
}

SCOPE: {
    my $current = Padre::DB->get_last_pod;
    ok !defined $current, 'current pod not defined';

    my @pods = Padre::DB->get_recent_pod;
    is_deeply \@pods, [], 'no pods yet'
       or diag Dumper \@pods;
    my @files = Padre::DB->get_recent_files;
    is_deeply \@files, [], 'no files yet';

    ok( ! Padre::DB->add_recent_pod('Test'), 'add_recent_pod' );
    @pods = Padre::DB->get_recent_pod;
    is_deeply \@pods, ['Test'], 'pods';
    is( Padre::DB->get_last_pod, 'Test', 'current is Test' );

    ok( ! Padre::DB->add_recent_pod('Test::More'), 'add_recent_pod' );
    @pods = Padre::DB->get_recent_pod;
    is_deeply \@pods, ['Test', 'Test::More'], 'pods';
    is( Padre::DB->get_last_pod, 'Test::More', 'current is Test::More' );
    is( Padre::DB->get_last_pod, 'Test', 'current is Test' );

# TODO next, previous,
# TODO limit number of items and see what happens
# TODO whne setting an element that was already in the list as recent
# it should become the last one!
}

SCOPE: {
    my @words = qw(One Two Three Four Five Six);
    foreach my $name (@words) {
        Padre::DB->add_recent_pod($name);
    }
    my @pods = Padre::DB->get_recent_pod;
    is_deeply \@pods, ['Test', 'Test::More', @words], 'pods';
    is( Padre::DB->get_last_pod, 'Six', 'current is Six' );

    is( $app->prev_module, 'Five', 'prev Five' );
    is( $app->prev_module, 'Four', 'prev Four' );
    is( Padre::DB->get_last_pod, 'Four', 'current is Four' );
    is( $app->next_module, 'Five', 'next Five' );
}
