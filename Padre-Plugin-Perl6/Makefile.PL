use strict;
use inc::Module::Install;

name           'Padre-Plugin-Perl6';
license        'perl';
author         'Gabor Szabo';
all_from       'lib/Padre/Plugin/Perl6.pm';

requires       'perl'                    => '5.010';

requires       'Padre'                    => '0.33';
requires       'Syntax::Highlight::Perl6' => '0.50';
requires       'URI'                      => '1.37';
requires       'Readonly'                 => '1.03';
requires       'IPC::Run3'                => '0.042';
requires       'File::Which'              => '0.05';

test_requires  'Test::More'              => '0.86';
test_requires  'Test::Exception'         => '0.27';
test_requires  'Test::NoWarnings'        => '0.084';
test_requires  'Test::NeedsDisplay'      => '1.05';
no_index       'directory' => [ qw{ t xt eg share inc privinc} ];

homepage       'http://padre.perlide.org/';
bugtracker     'http://padre.perlide.org/';
repository     'http://svn.perlide.org/padre/trunk/Padre-Plugin-Perl6';
 
WriteAll;
