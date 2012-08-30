use Test::More tests => 6;

use_ok( 'Padre::Unload', '0.96' );
use_ok( 'Padre::Task',   '0.96' );
use_ok( 'App::Nopaste',  '0.35' );


######
# let's check our subs/methods.
######

my @subs = qw( new run );

use_ok( 'Padre::Plugin::Nopaste::Task', @subs );

foreach my $subs (@subs) {
	can_ok( 'Padre::Plugin::Nopaste::Task', $subs );
}

done_testing();

1;

__END__
