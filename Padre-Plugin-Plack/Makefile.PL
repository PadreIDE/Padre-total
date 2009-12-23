use inc::Module::Install 0.91;

if ( -e 'MANIFEST.SKIP' ) {
    system( 'pod2text lib/Padre/Plugin/Plack.pm > README' );
}

name 'Padre-Plugin-Plack';
all_from 'lib/Padre/Plugin/Plack.pm';
author 'Patrick Donelan <pdonelan@cpan.org>';
license 'perl';

requires 'Padre' => '0.53';
requires 'Plack' => '0.9021';
requires 'File::Basename';
requires 'File::Find::Rule';
requires 'File::Which';
requires 'Proc::Killfam';
requires 'Scalar::Util';

test_requires 'Test::More';

install_share_with_mofiles; # install Locale::Msgfmt

auto_install;

WriteAll;
