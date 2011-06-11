use Test::More tests => 12;

use_ok( 'Padre',                 '0.84' );
use_ok( 'Padre::Plugin',         '0.84' );
use_ok( 'Padre::Wx::Role::Main', '0.84' );

TODO: {
	local $TODO = "Error: Can't locate Wx/Dialog.pm in \@INC";
	use_ok( 'Wx::Dialog', '0.84' );
}


######
# let's check our subs/methods.
######

my @subs = qw( padre_interfaces plugin_name menu_plugins_simple plugin_disable load_dialog_main );
use_ok( 'Padre::Plugin::Cookbook', @subs );

foreach my $subs (@subs) {
	can_ok( 'Padre::Plugin::Cookbook', $subs );
}


######
# let's check our lib's are here.
######
my $test_object;
require Padre::Plugin::Cookbook::Main;
$test_object = new_ok('Padre::Plugin::Cookbook::Main');

require Padre::Plugin::Cookbook::FBP::MainFB;
$test_object = new_ok('Padre::Plugin::Cookbook::FBP::MainFB');

done_testing();
