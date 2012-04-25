use Test::More tests => 7;

use_ok( 'Padre::Task::Syntax', '0.96' );


######
# let's check our subs/methods.
######

my @subs = qw( _parse_error _parse_error_win32 new run syntax );

use_ok( 'Padre::Plugin::YAML::Syntax', @subs );

foreach my $subs (@subs) {
	can_ok( 'Padre::Plugin::YAML::Syntax', $subs );
}


done_testing();

1;

__END__
