use Test::More tests => 7;

# use_ok( 'Padre::Unload', '0.94' );
# use_ok( 'Padre::Logger', '0.94' );


######
# let's check our subs/methods.
######

my @subs = qw( _count_utf_chars check dictionaries ignore
	new suggestions
);

use_ok( 'Padre::Plugin::SpellCheck::Engine', @subs );

foreach my $subs (@subs) {
	can_ok( 'Padre::Plugin::SpellCheck::Engine', $subs );
}


######
# let's check our lib's are here.
######
my $test_object;

# require Padre::Plugin::SpellCheck::FBP::Preferences;
# $test_object = new_ok('Padre::Plugin::SpellCheck::FBP::Checker');

done_testing();

1;

__END__
