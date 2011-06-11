use Test::More tests => 4;

use_ok('Padre::Plugin::Cookbook::FBP::MainFB');

######
# let's check our subs/methods.
######

my @subs = qw( new );
use_ok( 'Padre::Plugin::Cookbook::Main', @subs );

foreach my $subs (@subs) {
	can_ok( 'Padre::Plugin::Cookbook::Main', $subs );
}


######
# let's check our lib's are here.
######
my $test_object;

require Padre::Plugin::Cookbook::FBP::MainFB;
$test_object = new_ok('Padre::Plugin::Cookbook::FBP::MainFB');

done_testing();
