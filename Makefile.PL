use inc::Module::Install;

name     'Padre-Plugin-DataWalker';
all_from 'lib/Padre/Plugin/DataWalker.pm';
author   'Steffen Mueller <smueller@cpan.org>';
license  'perl';

homepage       'http://padre.perlide.org/';
repository     'http://svn.perlide.org/padre/trunk/Padre-Plugin-DataWalker/';

requires  'Padre'                => '0.47';
requires  'Wx::Perl::DataWalker' => '0.02';
requires  'YAML::XS'             => '0';

build_requires 'Test::More';

is_padre_plugin; # authors: Install Module::Install::PadrePlugin
auto_install;

install_share_with_mofiles; # install Locale::Msgfmt

WriteAll;

