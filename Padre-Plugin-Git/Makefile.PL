use inc::Module::Install;

name     'Padre-Plugin-Git';
all_from 'lib/Padre/Plugin/Git.pm';
author   'Kaare Rasmussen <kaare@cpan.org>';
license  'perl';

requires  'Capture::Tiny'  => '0.03';
requires  'Padre'          => '0.27';
requires  'File::Basename' => '0';
requires  'File::Spec'     => '0';

build_requires 'Test::More';

auto_install;

WriteAll;

