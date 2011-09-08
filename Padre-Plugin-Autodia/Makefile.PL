use strict;
use warnings;
use inc::Module::Install;

name 'Padre-Plugin-Autodia';
license 'perl';

author 'Aaron Trevena <aaron.trevena@gmail.com>';
author 'Ahmad M. Zawawi <ahmad.zawawi@gmail.com>';

all_from 'lib/Padre/Plugin/Autodia.pm';

requires 'Padre'   => '0.65';
requires 'Cwd'     => 0;
requires 'Autodia' => 0;

test_requires 'Test::More' => '0.47';
no_index 'directory'       => qw{ t xt eg share inc};

homepage 'http://padre.perlide.org/';
bugtracker 'http://padre.perlide.org/';
repository 'http://svn.perlide.org/padre/trunk/Padre-Plugin-Autodia';

is_padre_plugin; # authors: Install Module::Install::PadrePlugin

WriteAll;
