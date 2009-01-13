use inc::Module::Install;

name     'Padre-Plugin-SpellCheck';
all_from 'lib/Padre/Plugin/SpellCheck.pm';
author   'Fayland Lam <fayland@gmail.com>';
license  'perl';

requires 'Padre' => '0.25';
requires 'Text::Aspell';

build_requires 'Test::More';

auto_install;

WriteAll;

