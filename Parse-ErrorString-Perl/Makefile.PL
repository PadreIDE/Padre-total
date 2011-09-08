use strict;
use warnings;
use inc::Module::Install;

name           'Parse-ErrorString-Perl';
license        'perl';
author         'Petar Shangov, <pshangov at yahoo.com>';
author         'Gabor Szabo <http://szabgab.com/>';
author         'Ahmad M. Zawawi <ahmad.zawawi@gmail.com>';
all_from       'lib/Parse/ErrorString/Perl.pm';
requires       'Padre'                           => '0.80';
test_requires  'Test::More'              => '0.47';
no_index       'directory'               => qw{ t xt eg share inc};
homepage       'http://padre.perlide.org/';
bugtracker     'http://padre.perlide.org/';
repository     'http://svn.perlide.org/padre/trunk/Parse-ErrorString-Perl';

WriteAll;
