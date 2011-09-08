use strict;
use warnings;
use inc::Module::Install;

name           'Padre-Plugin-CSS';
license        'perl';
author         'Fayland Lam <fayland@gmail.com>';
author         'Alexandr Ciornii <alexchorny@gmail.com>';
author         'Ahmad M. Zawawi <ahmad.zawawi@gmail.com>';
all_from       'lib/Padre/Plugin/CSS.pm';
requires       'Padre'                           => '0.65';
requires       'WebService::Validator::CSS::W3C' => 0;
requires       'CSS::Minifier::XS'               => 0;
requires       'YAML::Tiny'                      => 0;
test_requires  'Test::More'              => '0.47';
no_index       'directory'               => qw{ t xt eg share inc};
homepage       'http://padre.perlide.org/';
bugtracker     'http://padre.perlide.org/';
repository     'http://svn.perlide.org/padre/trunk/Padre-Plugin-CSS';

is_padre_plugin; # authors: Install Module::Install::PadrePlugin

WriteAll;
