use Test::More tests => 23;

use_ok( 'Padre',                 '0.94' );
use_ok( 'Padre::Plugin',         '0.94' );
use_ok( 'Padre::Unload',         '0.94' );
use_ok( 'Padre::Locale',         '0.94' );
use_ok( 'Padre::Logger',         '0.94' );
use_ok( 'Padre::Wx',             '0.94' );
use_ok( 'Padre::Wx::Role::Main', '0.94' );


######
# let's check our subs/methods.
######

my @subs = qw( clean_dialog config padre_interfaces plugin_name menu_plugins
	plugin_disable plugin_enable plugin_preferences set_config spell_check );

use_ok( 'Padre::Plugin::SpellCheck', @subs );

foreach my $subs (@subs) {
	can_ok( 'Padre::Plugin::SpellCheck', $subs );
}

# all_from      lib/Padre/Plugin/SpellCheck.pm
# requires_from lib/Padre/Plugin/SpellCheck.pm
# requires_from lib/Padre/Plugin/SpellCheck/Dialog.pm
# requires_from lib/Padre/Plugin/SpellCheck/Engine.pm
# requires_from lib/Padre/Plugin/SpellCheck/Preferences.pm
######
# let's check our lib's are here.
######
my $test_object;
SKIP: {
	skip 'due to back call', 1 if 1;
	require Padre::Plugin::SpellCheck::Preferences;
	$test_object = new_ok('Padre::Plugin::SpellCheck::Preferences');
}
require Padre::Plugin::SpellCheck::FBP::Preferences;
$test_object = new_ok('Padre::Plugin::SpellCheck::FBP::Preferences');

require Padre::Plugin::SpellCheck::Engine;
$test_object = new_ok('Padre::Plugin::SpellCheck::Engine');
SKIP: {
	skip 'due to missing prameter', 1 if 1;
	require Padre::Plugin::SpellCheck::Dialog;
	$test_object = new_ok('Padre::Plugin::SpellCheck::Dialog');
}
require Padre::Plugin::SpellCheck::FBP::Dialog;
$test_object = new_ok('Padre::Plugin::SpellCheck::FBP::Dialog');

# require Padre::Plugin::Cookbook::Recipe03::About;
# $test_object = new_ok('Padre::Plugin::Cookbook::Recipe03::About');

# require Padre::Plugin::Cookbook::Recipe03::FBP::AboutFB;
# $test_object = new_ok('Padre::Plugin::Cookbook::Recipe03::FBP::AboutFB');

# require Padre::Plugin::Cookbook::Recipe04::Main;
# $test_object = new_ok('Padre::Plugin::Cookbook::Recipe04::Main');

# require Padre::Plugin::Cookbook::Recipe04::FBP::MainFB;
# $test_object = new_ok('Padre::Plugin::Cookbook::Recipe04::FBP::MainFB');

# require Padre::Plugin::Cookbook::Recipe04::About;
# $test_object = new_ok('Padre::Plugin::Cookbook::Recipe04::About');

# require Padre::Plugin::Cookbook::Recipe04::FBP::AboutFB;
# $test_object = new_ok('Padre::Plugin::Cookbook::Recipe04::FBP::AboutFB');
# done_testing();

done_testing();

1;

__END__


# use 5.008006;
# use Test::More;
# plan( tests => 42 );

# use_ok( 'Carp',                 '1.23' );
# use_ok( 'IO::Socket',           '1.31' );
# use_ok( 'IO::Socket::INET',     '1.31' );
# use_ok( 'PadWalker',            '1.92' );
# use_ok( 'Term::ReadLine',       '1.07' );
# use_ok( 'Term::ReadLine::Perl', '1.0303' );

# use_ok( 'Test::More',    '0.98' );
# use_ok( 'Test::Deep',    '0.108' );
# use_ok( 'Test::Class',   '0.36' );
# use_ok( 'File::HomeDir', '0.98' );
# use_ok( 'File::Temp',    '0.22' );
# use_ok( 'File::Spec',    '3.33' );


# ######
# # let's check our subs/methods.
# ######

# my @subs = qw( buffer filename get get_h_var get_lineinfo get_options get_p_exp
	# get_stack_trace get_v_vars get_value get_x_vars get_y_zero list_break_watch_action
	# list_subroutine_names listener module new quit remove_breakpoint row run
	# set_breakpoint set_option show_breakpoints show_line show_view step_in step_over
	# toggle_trace );

# use_ok( 'Debug::Client', @subs );

# foreach my $subs (@subs) {
	# can_ok( 'Debug::Client', $subs );
# }

# done_testing();

# 1;

# __END__
