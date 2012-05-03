use inc::Module::Install 1.06;

# Define metadata
name 'Padre-Plugin-Cookbook';
abstract 'Cookbook contains recipes to assist you in makeing your own Padre::Plugin';
license 'perl';
author 'Kevin Dawson <bowtie@cpan.org>';
# perl_version '5.010';

# All from our plugin
all_from      'lib/Padre/Plugin/Cookbook.pm';
requires_from 'lib/Padre/Plugin/Cookbook/Recipe01/Main.pm';
requires_from 'lib/Padre/Plugin/Cookbook/Recipe02/Main.pm';
requires_from 'lib/Padre/Plugin/Cookbook/Recipe03/Main.pm';
requires_from 'lib/Padre/Plugin/Cookbook/Recipe04/Main.pm';

# Padre version, should match that of the latest version, used in padre_interfaces, 
requires 'Padre'                => '0.96';

# required modules from CPAN
requires 'Moose'                => '2.06';
requires 'namespace::autoclean' => '0.13';
requires 'Data::Printer'        => '0.3';
requires 'POSIX' => '1.17';

# Optional if you have used the share directory
install_share;

# additinal
homepage 'http://padre.perlide.org/trac/wiki/PadrePluginDialog';
bugtracker 'http://padre.perlide.org/trac';
repository 'http://svn.perlide.org/padre/trunk/Padre-Plugin-Cookbook/';

WriteAll;
