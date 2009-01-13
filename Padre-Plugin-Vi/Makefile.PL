use strict;
use inc::Module::Install;

name           'Padre-Plugin-Vi';
license        'perl';
author         'Gabor Szabo <szabgab@gmail.com>';
all_from       'lib/Padre/Plugin/Vi.pm';
requires       'Padre'                   => '0.25';
requires       'Wx::Perl::Dialog'        => '0.04';
test_requires  'Test::More'              => '0.47';
no_index       'directory'               => qw{ t xt eg share inc};
homepage       'http://padre.perlide.org/';
bugtracker     'http://padre.perlide.org/';
repository     'http://svn.perlide.org/padre/trunk/Padre-Plugin-Vi';

WriteAll;
