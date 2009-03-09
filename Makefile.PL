use strict;
use lib 'privinc';
use inc::Module::Install;


name           'Padre-Plugin-PHP';
license        'perl';
author         'Gabor Szabo <szabgab@gmail.com>';
all_from       'lib/Padre/Plugin/PHP.pm';
requires       'Padre' => '0.28';

test_requires  'Test::More'              => '0.47';

no_index       'directory'               => qw{ t xt eg share inc privinc};

homepage       'http://padre.perlide.org/';
bugtracker     'http://padre.perlide.org/';
epository     'http://svn.perlide.org/padre/trunk/Padre-Plugin-PHP';

WriteAll;
