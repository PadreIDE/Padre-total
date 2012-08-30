use Test::More tests => 13;

use_ok( 'Padre::Unload', '0.96' );
use_ok( 'Moo',           '1.00' );


######
# let's check our subs/methods.
######

my @subs = qw( Codepeek Debian Gist PastebinCom Pastie Shadowcat Snitch Ubuntu servers ssh );

use_ok( 'Padre::Plugin::Nopaste::Services', @subs );

foreach my $subs (@subs) {
	can_ok( 'Padre::Plugin::Nopaste::Services', $subs );
}

done_testing();

1;

__END__
