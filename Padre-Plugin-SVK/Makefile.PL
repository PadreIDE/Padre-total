use inc::Module::Install;

name     'Padre-Plugin-SVK';
all_from 'lib/Padre/Plugin/SVK.pm';
author   'Gabor Szabo <szabgab@gmail.com>';
license  'perl';

requires  'Capture::Tiny'  => '0.03';
requires  'Padre'          => '0.27';
requires  'SVK'            => '0'; # was 2.0.2 but it complained that 2.2.1 is not new enough... 
requires  'File::Basename' => '0';
requires  'File::Spec'     => '0';

build_requires 'Test::More';

is_padre_plugin; # authors: Install Module::Install::PadrePlugin
auto_install;

WriteAll;

