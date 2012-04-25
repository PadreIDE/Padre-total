use Test::More tests => 6;

use_ok( 'Padre::Document', '0.96' );


######
# let's check our subs/methods.
######

my @subs = qw( task_functions task_outline task_syntax comment_lines_str );

use_ok( 'Padre::Plugin::YAML::Document', @subs );

foreach my $subs (@subs) {
	can_ok( 'Padre::Plugin::YAML::Document', $subs );
}


done_testing();

1;

__END__
