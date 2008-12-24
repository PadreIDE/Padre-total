use strict;
use lib 'privinc';
use inc::Module::Install;

name           'Padre-Plugin-Perldoc';
license        'perl';
author         'Gabor Szabo <szabgab@gmail.com>';
all_from       'lib/Padre/Plugin/Perldoc.pm';

requires       'Padre'           => '0.22';
requries       'Pod::POM::Web'   => '1.11';
requires       'PPI::HTML'       => '1.07';

test_requires  'Test::More'              => '0.47';
no_index       'directory'               => qw{ t xt eg share inc privinc};
homepage       'http://padre.perlide.org/';
bugtracker     'http://padre.perlide.org/';
repository     'http://svn.perlide.org/padre/trunk/Padre-Plugin-Perldoc';

WriteAll;
