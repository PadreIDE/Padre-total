use inc::Module::Install;

name 'Padre-Plugin-Plack';
all_from 'lib/Padre/Plugin/Plack.pm';
author 'Patrick Donelan <pdonelan@cpan.org>';
license 'perl';

requires 'Padre' => '0.53';
requires 'Plack' => '0.9021';
requires 'File::Basename';
requires 'File::Find::Rule';
requires 'File::Which';
requires 'Proc::Killfam';
requires 'Scalar::Util';

test_requires 'Test::More';

install_share('share');

auto_install;

WriteAll;
