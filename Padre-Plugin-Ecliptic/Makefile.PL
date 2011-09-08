use strict;
use warnings;
use inc::Module::Install;

name 'Padre-Plugin-Ecliptic';
license 'perl';
author 'Ahmad M. Zawawi <ahmad.zawawi@gmail.com>';

all_from 'lib/Padre/Plugin/Ecliptic.pm';
requires_from 'lib/Padre/Plugin/Ecliptic/QuickAssistDialog.pm';
requires_from 'lib/Padre/Plugin/Ecliptic/QuickModuleAccessDialog.pm';
requires_from 'lib/Padre/Plugin/Ecliptic/QuickOutlineAccessDialog.pm';

requires 'Padre'             => '0.91';
requires 'Class::XSAccessor' => '1.02';
requires 'File::Which'       => '0.05';
requires 'File::Find::Rule'  => 0;


test_requires 'Test::More' => '0.47';
no_index 'directory'       => qw{ t xt eg share inc};

homepage 'http://padre.perlide.org/';
bugtracker 'http://padre.perlide.org/';
repository 'http://svn.perlide.org/padre/trunk/Padre-Plugin-Ecliptic';

is_padre_plugin; # authors: Install Module::Install::PadrePlugin

WriteAll;
