use inc::Module::Install;

name     'Padre-Plugin-SDL';
all_from 'lib/Padre/Plugin/SDL.pm';
author   'Gabor Szabo <szabgab@gmail.com>';
license  'perl';

requires  'Padre'         => '0.43';

build_requires 'Test::More';

is_padre_plugin;
auto_install;

WriteAll;

