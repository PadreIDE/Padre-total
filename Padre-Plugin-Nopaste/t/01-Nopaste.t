use Test::More tests => 20;

use_ok( 'Padre',                 '0.94' );
use_ok( 'Padre::Plugin',         '0.94' );
use_ok( 'Padre::Unload',         '0.94' );
use_ok( 'Padre::Task',           '0.94' );
use_ok( 'Padre::Logger',         '0.94' );
use_ok( 'Padre::Wx',             '0.94' );
use_ok( 'Padre::Wx::Role::Main', '0.94' );


######
# let's check our subs/methods.
######

my @subs = qw( _config clean_dialog event_on_context_menu menu_plugins on_finish
	padre_interfaces paste_it plugin_disable plugin_enable plugin_icon
	plugin_name plugin_preferences 
);

use_ok( 'Padre::Plugin::Nopaste', @subs );

foreach my $subs (@subs) {
	can_ok( 'Padre::Plugin::Nopaste', $subs );
}


######
# let's check our lib's are here.
######
my $test_object;

# require Padre::Plugin::SpellCheck::Preferences;
# $test_object = new_ok('Padre::Plugin::SpellCheck::Preferences');

# require Padre::Plugin::Nopaste::Task;
# $test_object = new_ok('Padre::Plugin::Nopaste::Task');

# require Padre::Plugin::SpellCheck::Engine;
# $test_object = new_ok('Padre::Plugin::SpellCheck::Engine');

# require Padre::Plugin::SpellCheck::Checker;
# $test_object = new_ok('Padre::Plugin::SpellCheck::Checker');

# require Padre::Plugin::SpellCheck::FBP::Checker;
# $test_object = new_ok('Padre::Plugin::SpellCheck::FBP::Checker');


done_testing();

1;

__END__
