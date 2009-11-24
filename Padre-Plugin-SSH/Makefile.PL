use strict;
use inc::Module::Install;


name           'Padre-Plugin-SSH';
license        'perl';
author         'Steffen Mueller <smueller@cpan.org>';
all_from       'lib/Padre/Plugin/SSH.pm';

requires       'Padre'                           => '0.49';
requires       'Net::SSH::Perl'                  => '0';

test_requires  'Test::More'              => '0.47';

no_index       'directory'               => qw{ t xt eg share inc privinc};

homepage       'http://padre.perlide.org/';
bugtracker     'http://padre.perlide.org/';
repository     'http://svn.perlide.org/padre/trunk/Padre-Plugin-SSH';

is_padre_plugin; # authors: Install Module::Install::PadrePlugin

WriteAll;
