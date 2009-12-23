use inc::Module::Install;

name 'Padre-Plugin-Plack';
all_from 'lib/Padre/Plugin/Plack.pm';
author 'Patrick Donelan <pat@patspam.com>';
license 'perl';
requires 'Padre' => '0.53';
requires 'Plack' => '0.9021';
test_requires 'Test::More';

install_share('share');

auto_install;

WriteAll;
