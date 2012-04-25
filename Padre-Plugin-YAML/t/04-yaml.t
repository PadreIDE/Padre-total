use Test::More tests => 12;

use_ok( 'Padre',         '0.96' );
use_ok( 'Padre::Plugin', '0.96' );
use_ok( 'Padre::Unload', '0.96' );
use_ok( 'Padre::Wx',     '0.96' );


######
# let's check our subs/methods.
######

my @subs = qw( menu_plugins_simple padre_interfaces plugin_enable plugin_disable
	plugin_name registered_documents show_about
);

use_ok( 'Padre::Plugin::YAML', @subs );

foreach my $subs (@subs) {
	can_ok( 'Padre::Plugin::YAML', $subs );
}


done_testing();

1;

__END__
