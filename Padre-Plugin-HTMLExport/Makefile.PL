use strict;
use inc::Module::Install;

name           'Padre-Plugin-HTMLExport';
license        'perl';
author         'Gabor Szabo';
all_from       'lib/Padre/Plugin/HTMLExport.pm';

requires       'Padre'                    => '0.43';
requires       'Syntax::Highlight::Engine::Kate' => '0';

test_requires  'Test::More'              => '0.47';
test_requires  'Test::Exception'         => '0.27';
test_requires  'Test::NoWarnings'        => '0.084';
test_requires  'Test::NeedsDisplay'      => '1.05';
no_index       'directory' => [ qw{ t xt eg inc share privinc} ];

homepage       'http://padre.perlide.org/';
bugtracker     'http://padre.perlide.org/';
repository     'http://svn.perlide.org/padre/trunk/Padre-Plugin-HTMLExport';

is_padre_plugin; # authors: Install Module::Install::PadrePlugin

install_share_with_mofiles; # install Locale::Msgfmt

WriteAll;
