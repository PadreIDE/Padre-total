use strict;
use warnings;
use inc::Module::Install;

name 'Padre-Plugin-Nopaste';
license 'perl';
author 'Jerome Quelin <jquelin@gmail.com>';

all_from 'lib/Padre/Plugin/Nopaste.pm';
requires_from 'lib/Padre/Plugin/Nopaste/Task.pm';

requires 'Padre'                 => '0.91';
requires 'App::Nopaste'          => 0;
requires 'File::Basename'        => 0;
requires 'File::Spec::Functions' => 0;
requires 'Module::Util'          => 0;

test_requires 'Test::More' => '0.47';
no_index 'directory'       => qw{ t xt eg share inc};

homepage 'http://padre.perlide.org/';
bugtracker 'http://padre.perlide.org/';
repository 'http://svn.perlide.org/padre/trunk/Padre-Plugin-Nopaste';

is_padre_plugin; # authors: Install Module::Install::PadrePlugin

WriteAll;

