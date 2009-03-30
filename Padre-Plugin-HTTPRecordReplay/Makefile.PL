use strict;
use warnings;
use inc::Module::Install;

name           'Padre-Plugin-HTTPRecordReplay';
license        'perl';
author         'Gabor Szabo <szabgab@gmail.com>';
all_from       'lib/Padre/Plugin/HTTPRecordReplay.pm';

requires       'Padre'            => '0.32';
requires       'Sniffer::HTTP'    => '0';

test_requires  'Test::More'              => '0.47';
no_index       'directory'               => qw{ t xt eg share inc privinc};
homepage       'http://padre.perlide.org/';
bugtracker     'http://padre.perlide.org/';
repository     'http://svn.perlide.org/padre/trunk/Padre-Plugin-HTTPRecordReplay';

WriteAll;
