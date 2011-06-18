use inc::Module::Install;

name 'Padre-Plugin-Cookbook';
all_from 'lib/Padre/Plugin/Cookbook.pm';
requires_from 'lib/Padre/Plugin/Cookbook/Recipe01/Main.pm';
requires_from 'lib/Padre/Plugin/Cookbook/Recipe02/Main.pm';
requires_from 'lib/Padre/Plugin/Cookbook/Recipe03/Main.pm';
requires_from 'lib/Padre/Plugin/Cookbook/Recipe04/Main.pm';
author q{BOWTIE <kevin.dawson@btclick.com>};

perl_version '5.010001';

# causes warnning
# MakeMaker attribute "VERSION_FROM" is overriden; use "makemaker_append" to append values
# ie; if v0.14 -> 0.014000, what fun perl is :)
version_from 'lib/Padre/Plugin/Cookbook.pm';
license 'perl';

requires 'Moose' => '2.00';
requires 'namespace::autoclean' => '0.12';
requires 'Data::Printer' => '0.19';

test_requires 'Test::More' => '0.98';
test_requires 'Test::Perl::Critic' => '1.02'; 

auto_install;

WriteAll;

