use inc::Module::Install;

name     'Task-Padre-Plugins';
all_from 'lib/Task/Padre/Plugins.pm';
author   'Gabor Szabo';
license  'perl';

requires 'Padre::Plugin::AcmePlayCode' => '0.05';
requires 'Padre::Plugin::Alarm'        => '0.02';
requires 'Padre::Plugin::CPAN'         => '0.07';
requires 'Padre::Plugin::CSS'          => '0.02';
requires 'Padre::Plugin::Encrypt'	   => '0.03';
requires 'Padre::Plugin::HTML'         => '0.03';
requires 'Padre::Plugin::HTMLExport'   => '0.01';
requires 'Padre::Plugin::JavaScript'   => '0.22';
requires 'Padre::Plugin::PAR'          => '0.03';
requires 'Padre::Plugin::PerlCritic'   => '0.05';
requires 'Padre::Plugin::PerlTidy'     => '0.03';
requires 'Padre::Plugin::Pip'          => '0.13';
requires 'Padre::Plugin::ViewInBrowser';
requires 'Padre::Plugin::XML'          => '0.01';

feature 'Install experimental Padre plugin that runs on Parrot?',
    -default                => 0,
    'Padre::Plugin::Parrot' => '0.22';

feature 'Install Padre plugin for Perl6?',
    -default                => 0,
    'Padre::Plugin::Parrot' => '0.011';

build_requires 'Test::More';

auto_install;

WriteAll;
