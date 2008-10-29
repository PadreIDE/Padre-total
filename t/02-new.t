#!/usr/bin/perl

use strict;
use warnings;

use Test::NeedsDisplay;
use Test::More tests => 5; # + 16;
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
	my $same = Padre->inst;
	isa_ok($same, 'Padre');
	is $same, $app, 'Same';
}


SCOPE: {
	my $config = $app->config;
	is_deeply  $config,
		{
		experimental       => 0,
		pod_minlist        => 2,
		pod_maxlist        => 200,

		editor_linenumbers => 0,
		editor_eol         => 0,
		editor_tabwidth    => 4,
		editor_indentationguides => 0,
		editor_calltips    => 1,
		editor_use_tabs    => 1,

		search_terms       => [],
		replace_terms      => [],
		main_startup       => 'new',
		main_statusbar     => 1,
		main_output        => 0,
		projects           => {},
		run_save           => 'same',
		current_project    => '',
		bookmarks          => {},

		host               => {
			main_maximized => 0,
			main_top       => -1,
			main_left      => -1,
			main_width     => -1,
			main_height    => -1,
			run_command    => '',
			main_files     => [],
		},

		plugins => {},
	},
	'defaults';
}

__END__

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
