use strict;
use inc::Module::Install;

name           'Padre-Plugin-HTMLExport';
license        'perl';
author         'Gabor Szabo';
all_from       'lib/Padre/Plugin/HTMLExport.pm';

requires       'Padre'                    => '0.22';
requires       'Syntax::Highlight::Engine::Kate' => '0',

test_requires  'Test::More'              => '0.47';
test_requires  'Test::Exception'         => '0.27';
test_requires  'Test::NoWarnings'        => '0.084';
test_requires  'Test::NeedsDisplay'      => '1.05';
no_index       'directory' => [ qw{ t xt eg share inc privinc} ];

homepage       'http://padre.perlide.org/';
bugtracker     'http://padre.perlide.org/';
repository     'http://svn.perlide.org/padre/trunk/Padre-Plugin-HTMLExport';

WriteAll;
