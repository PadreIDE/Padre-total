use Test::More tests => 6;


######
# let's check our subs/methods.
######

my @subs = qw( _count_utf_chars check set_ignore_word new get_suggestions );

use_ok( 'Padre::Plugin::SpellCheck::Engine', @subs );

foreach my $subs (@subs) {
	can_ok( 'Padre::Plugin::SpellCheck::Engine', $subs );
}


done_testing();

1;

__END__
