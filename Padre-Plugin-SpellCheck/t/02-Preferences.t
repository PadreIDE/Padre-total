use Test::More tests => 15;

use_ok( 'Padre::Unload', '0.94' );
use_ok( 'Padre::Locale', '0.94' );
use_ok( 'Padre::Util',   '0.94' );
use_ok( 'Padre::Logger', '0.94' );
use_ok( 'Text::Aspell',  '0.09' );


######
# let's check our subs/methods.
######

my @subs = qw( _local_aspell_dictionaries _local_hunspell_dictionaries
	_on_button_save_clicked display_dictionaries
	new on_dictionary_chosen padre_locale_label set_up
);

use_ok( 'Padre::Plugin::SpellCheck::Preferences', @subs );

foreach my $subs (@subs) {
	can_ok( 'Padre::Plugin::SpellCheck::Preferences', $subs );
}


######
# let's check our lib's are here.
######
my $test_object;

require Padre::Plugin::SpellCheck::FBP::Preferences;
$test_object = new_ok('Padre::Plugin::SpellCheck::FBP::Preferences');

done_testing();

1;

__END__
