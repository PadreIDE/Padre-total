use strict;
use warnings;
use inc::Module::Install;

name 'Padre-Plugin-Dancer';
license 'perl';

author 'Aaron Trevena <aaron.trevena@gmail.com>';
author 'Ahmad M. Zawawi <ahmad.zawawi@gmail.com>';

all_from 'lib/Padre/Plugin/Dancer.pm';
requires_from 'lib/Padre/Plugin/Dancer/NewApp.pm';
requires_from 'lib/Padre/Plugin/Catalyst/Util.pm';

requires 'Padre'      => '0.91';
requires 'Dancer'     => 0;
requires 'File::Spec' => 0;

test_requires 'Test::More' => '0.47';
no_index 'directory'       => qw{ t xt eg share inc};

homepage 'http://padre.perlide.org/';
bugtracker 'http://padre.perlide.org/';
repository 'http://svn.perlide.org/padre/trunk/Padre-Plugin-Dancer';

is_padre_plugin; # authors: Install Module::Install::PadrePlugin

WriteAll;
