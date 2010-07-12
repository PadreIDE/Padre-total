use strict;
use lib 'privinc';
use inc::Module::Install;


name           'Padre-Plugin-Kate';
license        'perl';
author         'Gabor Szabo <szabgab@gmail.com>';
all_from       'lib/Padre/Plugin/Kate.pm';

requires       'Padre'                           => '0.65';
requires       'Syntax::Highlight::Engine::Kate' => '0.05';

test_requires  'Test::More'              => '0.47';

no_index       'directory'               => qw{ t xt eg share inc privinc};

homepage       'http://padre.perlide.org/';
bugtracker     'http://padre.perlide.org/';
repository     'http://svn.perlide.org/padre/trunk/Padre-Plugin-Kate';

is_padre_plugin; # authors: Install Module::Install::PadrePlugin

WriteAll;
