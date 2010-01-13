use inc::Module::Install 0.91;

if ( -e 'MANIFEST.SKIP' ) {
    system( 'pod2text lib/Padre/Plugin/PerlTidy.pm > README' );
}

all_from      'lib/Padre/Plugin/PerlTidy.pm';
requires      'Padre' => '0.54';
requires      'Perl::Tidy';
test_requires 'Test::More';

homepage       'http://padre.perlide.org/';
repository     'http://svn.perlide.org/padre/trunk/Padre-Plugin-PerlTidy';

extra_tests;
is_padre_plugin; # authors: Install Module::Install::PadrePlugin

install_share_with_mofiles; # install Locale::Msgfmt

WriteAll;
