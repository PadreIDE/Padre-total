use Test::More tests => 6;

use_ok( 'Padre::Task::Syntax', '0.94' );


######
# let's check our subs/methods.
######

my @subs = qw( _parse_error new run syntax );

use_ok( 'Padre::Plugin::YAML::Syntax', @subs );

foreach my $subs (@subs) {
	can_ok( 'Padre::Plugin::YAML::Syntax', $subs );
}


done_testing();

1;

__END__
