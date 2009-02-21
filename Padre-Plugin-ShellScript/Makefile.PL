use strict;
use inc::Module::Install;

name           'Padre-Plugin-ShellScript';
license        'perl';
author         'Claudio Ramirez';
all_from       'lib/Padre/Plugin/ShellScript.pm';

requires       'perl'                    => '5.008001';
requires       'Exporter'                => 0;
requires       'Padre'                   => '0.27';
requires       'Class::Autouse'          => '1.26';

test_requires  'Test::More'              => '0.47';
test_requires  'Test::NeedsDisplay'      => '1.05';
test_requires  'Test::NoWarnings'        => '0.084';
no_index       'directory' => [ qw{ t xt eg share inc privinc} ];

homepage       'http://padre.perlide.org/';
bugtracker     'http://padre.perlide.org/';
repository     'http://svn.perlide.org/padre/trunk/Padre-Plugin-ShellScript';
#mailinglist    'http://mail.perlide.org/mailman/listinfo/padre-dev';
 
WriteAll;
