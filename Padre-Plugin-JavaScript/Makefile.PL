use strict;
use inc::Module::Install;

name           'Padre-Plugin-JavaScript';
license        'perl';
author         'Gabor Szabo';
all_from       'lib/Padre/Plugin/JavaScript.pm';

requires       'perl'                    => '5.008001';
requires       'Exporter'                => 0;
requires       'Padre'                   => '0.21';
requires       'Class::Autouse'          => '1.26';
requires       'JavaScript::Beautifier'  => '0.03';
requires       'JavaScript::Minifier::XS';

test_requires  'Test::More'              => '0.47';
test_requires  'Test::NeedsDisplay'      => '1.05';
test_requires  'Test::NoWarnings'        => '0.084';
no_index       'directory' => [ qw{ t xt eg share inc privinc} ];

homepage       'http://padre.perlide.org/';
bugtracker     'http://padre.perlide.org/';
repository     'http://svn.perlide.org/padre/trunk/Padre-Plugin-JavaScript';
#mailinglist    'http://mail.perlide.org/mailman/listinfo/padre-dev';
 
WriteAll;
