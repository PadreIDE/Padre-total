#!/usr/bin/env perl

use strict;
use warnings;

# Turn on $OUTPUT_AUTOFLUSH
$| = 1;

use Test::More tests => 10;

use_ok( 'Padre',           '0.92' );
use_ok( 'Padre::Plugin',   '0.92' );
use_ok( 'Padre::Wx::Main', '0.92' );
use_ok( 'Padre::Logger',   '0.92' );


######
# let's check our subs/methods.
######

my @subs = qw( critic menu_plugins padre_interfaces plugin_disable plugin_name );
use_ok( 'Padre::Plugin::PerlCritic', @subs );

foreach my $subs (@subs) {
	can_ok( 'Padre::Plugin::PerlCritic', $subs );
}


done_testing();

1;

__END__
