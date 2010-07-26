use inc::Module::Install;

name     'Padre-Plugin-ClassSniff';
all_from 'lib/Padre/Plugin/ClassSniff.pm';
author   'Steffen Mueller <smueller@cpan.org>';
license  'perl';

homepage       'http://padre.perlide.org/';
repository     'http://svn.perlide.org/padre/trunk/Padre-Plugin-ClassSniff/';

requires  'Padre'          => '0.43';
requires  'Class::Sniff'   => '0.08';

build_requires 'Test::More';

is_padre_plugin; # authors: Install Module::Install::PadrePlugin
auto_install;

install_share_with_mofiles;

WriteAll;

