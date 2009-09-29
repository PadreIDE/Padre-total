use inc::Module::Install;

name 'Padre-Plugin-WebGUI';
all_from 'lib/Padre/Plugin/WebGUI.pm';
author 'Patrick Donelan <pat@patspam.com>';
license 'perl';
requires 'Padre' => '0.47';
requires 'LWP::UserAgent';
test_requires 'Test::More';
recommends 'JSON::XS' => '2.24';

install_share('share');

auto_install;

WriteAll;
