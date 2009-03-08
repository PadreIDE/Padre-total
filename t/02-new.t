#!/usr/bin/perl

use strict;
use warnings;
# use Test::NeedsDisplay ':skip_all';
use Test::More;
BEGIN {
	if (not $ENV{DISPLAY} and not $^O eq 'MSWin32') {
		plan skip_all => 'Needs DISPLAY';
		exit 0;
	}
}
# Move to Run menux
plan( tests => 63 );
#plan( tests => 62 );
use Test::NoWarnings;
use t::lib::Padre;
use Padre;

my $app = Padre->new;
isa_ok($app, 'Padre');

SCOPE: {
	my $ide = Padre->ide;
	isa_ok($ide, 'Padre');
	refis( $ide, $app, '->ide matches ->new' );
}

SCOPE: {
	my $config = $app->config;
	isa_ok( $config, 'Padre::Config' );

	is( $config->experimental             => 0              );
	is( $config->main_startup             => 'new'          );
	is( $config->main_lockinterface       => 1              );
	is( $config->main_functions           => 0              );
	is( $config->main_functions_order     => 'alphabetical' );
	is( $config->main_outline             => 0              );
	is( $config->main_directory           => 0              );
	is( $config->main_output              => 0              );
	is( $config->main_output_ansi         => 1              );
	is( $config->main_syntaxcheck         => 0              );
	is( $config->main_errorlist           => 0              );
	is( $config->main_statusbar           => 1              );
	is( $config->editor_font              => ''             );
	is( $config->editor_linenumbers       => 1              );
	is( $config->editor_eol               => 0              );
	is( $config->editor_indentationguides => 0              );
	is( $config->editor_calltips          => 0              );
	is( $config->editor_autoindent        => 'deep'         );
	is( $config->editor_whitespace        => 0              );
	is( $config->editor_folding           => 0              );
	is( $config->editor_wordwrap          => 0              );
	is( $config->editor_currentline       => 1              );
	is( $config->editor_currentline_color => 'FFFF04'       );
	is( $config->editor_indent_auto       => 1              );
	is( $config->editor_indent_tab_width  => 8              );
	is( $config->editor_indent_width      => 8              );
	is( $config->editor_indent_tab        => 1              );
	is( $config->editor_beginner          => 1              );
	is( $config->find_case                => 1              );
	is( $config->find_regex               => 0              );
	is( $config->find_reverse             => 0              );
	is( $config->find_first               => 0              );
	is( $config->find_nohidden            => 1              );
	is( $config->find_quick               => 0              );
	is( $config->ppi_highlight            => 0              );
	is( $config->ppi_highlight_limit      => 2000           );
	is( $config->run_save                 => 'same'         );
# Move to Run menu
#	is( $config->run_stacktrace           => 0              );
	is( $config->threads                  => 1              );
	is( $config->locale                   => ''             );
	is( $config->locale_perldiag          => ''             );
	is( $config->editor_style             => 'default'      );
	is( $config->main_maximized           => 0              );
	is( $config->main_top                 => 40             );
	is( $config->main_left                => 20             );
	is( $config->main_width               => 600            );
	is( $config->main_height              => 400            );
}





#####################################################################
# Internal Structure Tests

# These test that the internal structure of the application matches
# expected normals, and that structure navigation methods works normally.
SCOPE: {
	my $padre = Padre->ide;
	isa_ok( $padre, 'Padre' );

	# The Wx::App(lication)
	my $app = $padre->wx;
	isa_ok( $app, 'Padre::Wx::App' );

	# The main window
	my $main = $app->main;
	isa_ok( $main, 'Padre::Wx::Main' );

	# The main menu
	my $menu = $main->menu;
	isa_ok( $menu, 'Padre::Wx::Menubar' );
	refis( $menu->main, $main, 'Menubar ->main gets the main window' );

	# A submenu
	my $file = $menu->file;
	isa_ok( $file, 'Padre::Wx::Menu' );

	# The notebook
	my $notebook = $main->notebook;
	isa_ok( $notebook, 'Padre::Wx::Notebook' );

	# Current context
	my $current = $main->current;
	isa_ok( $current, 'Padre::Current' );
	isa_ok( $current->main,     'Padre::Wx::Main' );
	isa_ok( $current->notebook, 'Padre::Wx::Notebook'   );
	refis(  $current->main,     $main,     '->current->main ok'     );
	refis(  $current->notebook, $notebook, '->current->notebook ok' );
}
