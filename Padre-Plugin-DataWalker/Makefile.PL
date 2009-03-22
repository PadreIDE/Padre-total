use inc::Module::Install;

name     'Padre-Plugin-DataWalker';
all_from 'lib/Padre/Plugin/DataWalker.pm';
author   'Steffen Mueller <smueller@cpan.org>';
license  'perl';

requires  'Padre'                => '0.29';
requires  'Wx::Perl::DataWalker' => '0.01';
requires  'YAML::XS'             => '0';

build_requires 'Test::More';

is_padre_plugin; # authors: Install Module::Install::PadrePlugin
auto_install;

WriteAll;

