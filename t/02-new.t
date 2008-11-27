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
		editor_autoindent  => 'deep',
		editor_whitespaces => 0,

		search_terms       => [],
		replace_terms      => [],
		main_startup       => 'new',
		main_statusbar     => 1,
		main_output        => 0,
		main_rightbar      => 1,
		projects           => {},
		run_save           => 'same',
		current_project    => '',
		bookmarks          => {},

		host               => {
			main_maximized => 0,
			main_top       => 20,
			main_left      => 40,
			main_width     => 600,
			main_height    => 400,
			run_command    => '',
			main_files     => [],
			main_files_pos => [],
		},

		plugins => {},
	},
	'defaults';
}

__END__

