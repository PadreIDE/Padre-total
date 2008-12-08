use inc::Module::Install 0.77;

if ( -e 'MANIFEST.SKIP' ) {
    system( 'pod2text lib/Padre/Plugin/PerlTidy.pm > README' );
}

perl_version '5.008001';

name 'Padre-Plugin-PerlTidy';
all_from 'lib/Padre/Plugin/PerlTidy.pm';

test_requires 'Test::More';

requires 'Padre' => '0.21';
requires 'Perl::Tidy';

is_padre_plugin;

WriteAll;
