use inc::Module::Install 1.01;

# Define metadata
abstract 'Cookbook contains recipes to assist you in makeing your own Padre::Plugin';

# All from our plugin
all_from      'lib/Padre/Plugin/Cookbook.pm';
requires_from 'lib/Padre/Plugin/Cookbook/Recipe01/Main.pm';
requires_from 'lib/Padre/Plugin/Cookbook/Recipe02/Main.pm';
requires_from 'lib/Padre/Plugin/Cookbook/Recipe03/Main.pm';
requires_from 'lib/Padre/Plugin/Cookbook/Recipe04/Main.pm';

# Padre version, should match that of the latest version, used in padre_interfaces, 
requires 'Padre'                => '0.90';

# required modules from CPAN
requires 'Moose'                => '2.00';
requires 'namespace::autoclean' => '0.12';
requires 'Data::Printer'        => '0.19';

# Optional if you have used the share directory
install_share;

WriteAll;
