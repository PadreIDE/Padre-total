use strict;
use warnings;
use inc::Module::Install;

name           'Padre-Plugin-SQL';
license        'perl';
author         'Gabor Szabo <szabgab@gmail.com>';
all_from       'lib/Padre/Plugin/SQL.pm';
requires       'Padre'                   => '0.62';
test_requires  'Test::More'              => '0.47';
no_index       'directory'               => qw{ t xt eg share inc};
homepage       'http://padre.perlide.org/';
bugtracker     'http://padre.perlide.org/';
repository     'http://svn.perlide.org/padre/trunk/Padre-Plugin-SQL';

is_padre_plugin; # authors: Install Module::Install::PadrePlugin

WriteAll;
