#!/usr/bin/perl

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 11;
use Madre::DB;

# Drop the example user if it exists
ok(
	Madre::DB::User->delete(
		'where email = ?',
		'example@example.com',
	),
	'Cleared existing example user',
);

# Drop the example instance if it exists
ok(
	Madre::DB::Instance->delete(
		'where instance_id = ?',
		'byY9pVbVhDUWSQq4IO16wTPi9FZbaaiJ5Bla6By51fDO6Ziwwjn3DftyHkiPqclC'
	),
	'Cleared existing example instance',
);

# Sample configuration file
my $config_yml = <<'END_YAML';
---
editor_right_margin_column: 76
editor_right_margin_enable: 1
main_cpan: 0
main_directory: 1
main_directory_panel: left
main_foundinfiles_panel: bottom
main_functions: 0
main_lockinterface: 1
main_outline: 0
main_output: 0
main_syntax: 0
main_syntax_panel: bottom
main_tasks: 0
main_tasks_panel: bottom
main_vcs: 0
nth_startup: 106
vcs_unversioned_shown: 0
END_YAML

# Sample popularity contest entry
my $popcon = <<'END_YAML';
---
action.edit.copy: 6
action.edit.cut: 10
action.edit.paste: 15
action.edit.undo: 2
action.file.new: 2
action.file.open: 1
action.file.save: 151
action.file.save_as: 2
action.perl.vertically_align_selected: 7
action.plugins.plugin_manager: 1
action.search.replace: 6
action.tools.preferences: 2
action.view.syntax: 1
mime.application_x-perl: 11
mime.text_x-perltt: 7
mime.text_x-pod: 4
mime.text_x-yaml: 1
padre.instance: byY9pVbVhDUWSQq4IO16wTPi9FZbaaiJ5Bla6By51fDO6Ziwwjn3DftyHkiPqclC
padre.uptime: 3490
padre.version: 0.95
perl.archname: MSWin32-x86-multi-thread
perl.osname: MSWin32
perl.version: v5.10.1
perl.wxversion: 0.9903
wx.version_string: 'wxWidgets 2.8.10'
END_YAML





######################################################################
# Main Database Tests

# Create the test user
my $user = Madre::DB::User->create(
	email    => 'example@example.com',
	password => 'abcdefg',
);
isa_ok( $user, 'Madre::DB::User' );
ok( $user->user_id, '->user_id ok' );
ok( $user->created, '->created ok' );

# Create the test config
my $config = Madre::DB::Config->create(
	user_id => $user->user_id,
	data    => $config_yml,
);
isa_ok( $config, 'Madre::DB::Config' );
ok( $config->config_id, '->config_id ok' );
ok( $config->modified,  '->modified ok'  );

# Create the test instance
my $instance = Madre::DB::Instance->create(
	instance_id => 'byY9pVbVhDUWSQq4IO16wTPi9FZbaaiJ5Bla6By51fDO6Ziwwjn3DftyHkiPqclC',
	padre       => '0.94',
	perl        => 'v5.10.1',
	osname      => 'MSWin32',
	data        => $popcon,
);
isa_ok( $instance, 'Madre::DB::Instance' );
ok( $instance->created,  '->created ok'  );
ok( $instance->modified, '->modified ok' );

1;
