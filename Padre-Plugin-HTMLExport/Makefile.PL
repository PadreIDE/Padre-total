use strict;
use warnings;
use inc::Module::Install;

name 'Padre-Plugin-HTMLExport';
license 'perl';

author 'Fayland Lam <fayland@gmail.com>';
author 'Ahmad M. Zawawi <ahmad.zawawi@gmail.com>';

all_from 'lib/Padre/Plugin/HTMLExport.pm';

requires 'Padre'                           => '0.91';
requires 'Syntax::Highlight::Engine::Kate' => 0;
requires 'File::Basename'                  => 0;

test_requires 'Test::More' => '0.47';
no_index 'directory'       => qw{ t xt eg share inc};

homepage 'http://padre.perlide.org/';
bugtracker 'http://padre.perlide.org/';
repository 'http://svn.perlide.org/padre/trunk/Padre-Plugin-HTMLExport';

is_padre_plugin; # authors: Install Module::Install::PadrePlugin

WriteAll;
