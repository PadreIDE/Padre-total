use inc::Module::Install 0.77;

if ( -e 'MANIFEST.SKIP' ) {
    system( 'pod2text lib/Padre/Plugin/PerlTidy.pm > README' );
}

all_from      'lib/Padre/Plugin/PerlTidy.pm';
requires      'Padre' => '0.26';
requires      'Perl::Tidy';
test_requires 'Test::More';

extra_tests;
is_padre_plugin;

WriteAll;
