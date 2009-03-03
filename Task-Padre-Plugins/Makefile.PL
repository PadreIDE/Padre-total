use inc::Module::Install;

name     'Task-Padre-Plugins';
all_from 'lib/Task/Padre/Plugins.pm';
author   'Gabor Szabo';
license  'perl';

requires 'Padre::Plugin::AcmePlayCode'   => '0.08';
requires 'Padre::Plugin::Alarm'          => '0.02';
requires 'Padre::Plugin::CommandLine'    => '0.04';
requires 'Padre::Plugin::CSS'            => '0.05';
requires 'Padre::Plugin::Encode'         => '0.1.3';
requires 'Padre::Plugin::Encrypt'	     => '0.05';
requires 'Padre::Plugin::HTML'           => '0.08';
requires 'Padre::Plugin::HTMLExport'     => '0.04';
requires 'Padre::Plugin::InstallPARDist' => '0.01';
requires 'Padre::Plugin::JavaScript'     => '0.25';
requires 'Padre::Plugin::PAR'            => '0.04';
requires 'Padre::Plugin::PerlCritic'     => '0.06';
requires 'Padre::Plugin::PerlTidy'       => '0.05';
requires 'Padre::Plugin::Pip'            => '0.13';
requires 'Padre::Plugin::SVK'            => '0.01';
requires 'Padre::Plugin::Vi'             => '0.21';		
requires 'Padre::Plugin::ViewInBrowser'  => '0.06';;
requires 'Padre::Plugin::XML'            => '0.05';

feature 'Install experimental Padre plugin that runs on Parrot?',
    -default                => 0,
    'Padre::Plugin::Parrot' => '0.22';

feature 'Install Padre plugin for Perl6?',
    -default                => 0,
    'Padre::Plugin::Perl6' => '0.026';

feature 'Enable spell check in Padre?',
    -default                => 0,
    'Padre::Plugin::SpellCheck' => '0.01';

build_requires 'Test::More';

auto_install;

WriteAll;
