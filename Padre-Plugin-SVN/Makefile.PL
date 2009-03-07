use inc::Module::Install;

name     'Padre-Plugin-SVN';
all_from 'lib/Padre/Plugin/SVN.pm';
author   'Gabor Szabo <szabgab@gmail.com>';
license  'perl';

#requires  'Capture::Tiny' => '0.03';
requires  'Padre'         => '0.27';
#requires  'VCI'           => '0.5.2';

build_requires 'Test::More';

auto_install;

WriteAll;

