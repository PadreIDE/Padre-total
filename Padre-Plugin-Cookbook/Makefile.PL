use inc::Module::Install 1.01;

# Define metadata
abstract 'Cookbook contains recipes to assist you in makeing your own Padre::Plugin';

# causes warnning
# MakeMaker attribute "VERSION_FROM" is overriden; use "makemaker_append" to append values
# ie; if v0.14 -> 0.014000, what fun perl is :)
all_from      'lib/Padre/Plugin/Cookbook.pm';
requires_from 'lib/Padre/Plugin/Cookbook/Recipe01/Main.pm';
requires_from 'lib/Padre/Plugin/Cookbook/Recipe02/Main.pm';
requires_from 'lib/Padre/Plugin/Cookbook/Recipe03/Main.pm';
requires_from 'lib/Padre/Plugin/Cookbook/Recipe04/Main.pm';

requires 'Mouse'                => '0.93';
# requires 'Moose'                => '2.00';
# requires 'namespace::autoclean' => '0.12';
requires 'Data::Printer'        => '0.19';

WriteAll;
