use inc::Module::Install;

name     'File-Archiver';
all_from 'lib/File/Archiver.pm';
author   'Gabor Szabo <szabgab@gmail.com>';
license  'perl';

build_requires 'Test::More';

auto_install;

WriteAll;

