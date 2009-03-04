use inc::Module::Install;

name     'Padre-Plugin-SVK';
all_from 'lib/Padre/Plugin/SVK.pm';
author   'Gabor Szabo <szabgab@gmail.com>';
license  'perl';

requires  'Capture::Tiny' => '0.03';
requires  'Padre'         => '0.27';
requires  'SVK'           => '2.0.2';

build_requires 'Test::More';

auto_install;

WriteAll;

