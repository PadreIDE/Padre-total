use inc::Module::Install 0.92;

name     'Padre-Plugin-Git';
all_from 'lib/Padre/Plugin/Git.pm';
author   'Kaare Rasmussen <kaare@cpan.org>';
license  'perl';

homepage       'http://padre.perlide.org/';
repository     'http://svn.perlide.org/padre/trunk/Padre-Plugin-Git/';

requires  'Capture::Tiny'  => '0.03';
requires  'Padre'          => '0.67';
requires  'File::Basename' => '0';
requires  'File::Spec'     => '0';

build_requires 'Test::More';

is_padre_plugin; # authors: Install Module::Install::PadrePlugin
auto_install;

WriteAll;

