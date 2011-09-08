use strict;
use warnings;
use inc::Module::Install;

name 'Padre-Plugin-Parrot';
license 'perl';

author 'Gabor Szabo L<http://szabgab.com/>';
author 'Ahmad M. Zawawi <ahmad.zawawi@gmail.com>';

all_from 'lib/Padre/Plugin/Parrot.pm';
requires_from 'lib/Padre/Plugin/Parrot/ColorizeTask.pm';
requires_from 'lib/Padre/Plugin/Parrot/HL.pm';

requires 'Padre'          => '0.91';
requires 'File::ShareDir' => 0;
requires 'Parrot::Embed'  => 0;
requires 'Scalar::Util'   => 0;
requires 'File::Temp'     => 0;

test_requires 'Test::More' => '0.47';
no_index 'directory'       => qw{ t xt eg share inc};

homepage 'http://padre.perlide.org/';
bugtracker 'http://padre.perlide.org/';
repository 'http://svn.perlide.org/padre/trunk/Padre-Plugin-Parrot';

is_padre_plugin; # authors: Install Module::Install::PadrePlugin

WriteAll;
