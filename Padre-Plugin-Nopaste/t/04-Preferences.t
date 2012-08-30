use Test::More tests => 12;

use_ok( 'Padre::Unload', '0.96' );


######
# let's check our subs/methods.
######

my @subs = qw( _display_channels _display_servers _set_up new
	on_button_reset_clicked on_button_save_clicked on_server_chosen refresh
);

use_ok( 'Padre::Plugin::Nopaste::Preferences', @subs );

foreach my $subs (@subs) {
	can_ok( 'Padre::Plugin::Nopaste::Preferences', $subs );
}


######
# let's check our lib's are here.
######
my $test_object;

require Padre::Plugin::Nopaste::Services;
$test_object = new_ok('Padre::Plugin::Nopaste::Services');

require Padre::Plugin::Nopaste::FBP::Preferences;
$test_object = new_ok('Padre::Plugin::Nopaste::FBP::Preferences');

done_testing();

1;

__END__
