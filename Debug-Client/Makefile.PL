use 5.006;
use strict;
use lib 'privinc';
use inc::Module::Install 0.86;






name           'Debug-Client';
license        'perl';
author         'Gabor Szabo';
all_from       'lib/Debug/Client.pm';
requires       'perl'                     => '5.006';
requires       'Carp'                     => '0';
requires       'IO::Socket'               => '0',
test_requires  'Test::More'               => '0.47';
test_requires  'Test::Deep'               => '0';

no_index       'directory'                => qw{ t xt eg share inc privinc };
homepage       'http://padre.perlide.org/';
bugtracker     'http://padre.perlide.org/';
repository     'http://svn.perlide.org/padre/trunk/Debug-Client/';

WriteAll;
