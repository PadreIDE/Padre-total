use strict;
use lib 'privinc';
use inc::Module::Install;

name           'Padre-Plugin-PSI';
license        'perl';
author         'Gabor Szabo <szabgab@gmail.com>';
all_from       'lib/Padre/Plugin/PSI.pm';

requires       'Padre'          => '0.29';
requires       'Inline::Rakudo' => '0.02';

test_requires  'Test::More'              => '0.47';

no_index       'directory'               => qw{ t xt eg share inc privinc};
homepage       'http://padre.perlide.org/';
bugtracker     'http://padre.perlide.org/';
repository     'http://svn.perlide.org/padre/trunk/Padre-Plugin-PSI';

WriteAll;
