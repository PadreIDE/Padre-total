use inc::Module::Install;

name     'Task-Padre-Plugins';
all_from 'lib/Task/Padre/Plugins.pm';
author   'Gabor Szabo';
license  'perl';

homepage       'http://padre.perlide.org/';
repository     'http://svn.perlide.org/padre/trunk/Task-Padre-Plugins/';

requires 'Padre' => '0.36';
requires 'Padre::Plugin::AcmePlayCode' => '0.11';
requires 'Padre::Plugin::Alarm' => '0.07';
requires 'Padre::Plugin::Autoformat' => '1.1.2';
requires 'Padre::Plugin::CSS' => '0.08';
requires 'Padre::Plugin::CommandLine' => '0.02';
requires 'Padre::Plugin::DataWalker' => '0.01';
requires 'Padre::Plugin::Debugger' => '0.2';
requires 'Padre::Plugin::Ecliptic' => '0.08';
requires 'Padre::Plugin::Encode' => '0.1.3';
requires 'Padre::Plugin::Encrypt' => '0.06';
requires 'Padre::Plugin::HTML' => '0.09';
requires 'Padre::Plugin::HTMLExport' => '0.01';
requires 'Padre::Plugin::InstallPARDist' => '0.01';
requires 'Padre::Plugin::JavaScript' => '0.25';
requires 'Padre::Plugin::Nopaste' => '0.2.1';
requires 'Padre::Plugin::PAR' => '0.05';
requires 'Padre::Plugin::PerlCritic' => '0.06';
requires 'Padre::Plugin::PerlTidy' => '0.06';
requires 'Padre::Plugin::Vi' => '0.21';
requires 'Padre::Plugin::ViewInBrowser' => '0.07';
requires 'Padre::Plugin::XML' => '0.06';

feature 'Simple Catalyst helper interface for Padre',
	-default => 0,
	'Padre::Plugin::Catalyst' => '0.04';
feature 'Simple Git interface for Padre',
	-default => 0,
	'Padre::Plugin::Git' => '0.01';
feature 'Simple Mojolicious helper interface for Padre',
	-default => 0,
	'Padre::Plugin::Mojolicious' => '0.03';
feature 'Experimental Padre plugin written in Perl 6',
	-default => 0,
	'Padre::Plugin::PSI' => '0.01';
feature 'Experimental Padre plugin that runs on Parrot',
	-default => 0,
	'Padre::Plugin::Parrot' => '0.23';
feature 'Padre plugin for Perl6',
	-default => 0,
	'Padre::Plugin::Perl6' => '0.41';
feature 'Simple SVK interface for Padre',
	-default => 0,
	'Padre::Plugin::SVK' => '0.02';
feature 'Simple SVN interface for Padre',
	-default => 0,
	'Padre::Plugin::SVN' => '0.01';
feature 'check spelling in Padre',
	-default => 0,
	'Padre::Plugin::SpellCheck' => '1.1.1';

build_requires 'Test::More';

auto_install;

WriteAll;
