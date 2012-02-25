use Test::More tests => 7;


######
# let's check our subs/methods.
######

my @subs = qw( _count_utf_chars _init check get_suggestions new set_ignore_word);

use_ok( 'Padre::Plugin::SpellCheck::Engine', @subs );

foreach my $subs (@subs) {
	can_ok( 'Padre::Plugin::SpellCheck::Engine', $subs );
}


done_testing();

1;

__END__
