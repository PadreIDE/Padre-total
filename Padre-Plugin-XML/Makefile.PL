use strict;
use warnings;
use inc::Module::Install;

name           'Padre-Plugin-XML';
license        'perl';
author         'Fayland Lam <fayland@gmail.com>';
all_from       'lib/Padre/Plugin/XML.pm';
requires       'Padre'                           => '0.86';
requires       'WebService::Validator::CSS::W3C' => 0;
requires       'XML::Tidy'                       => 1,
requires       'XML::LibXML'                     => '1.67',
test_requires  'Test::More'              => '0.47';
no_index       'directory'               => qw{ t xt eg share inc};
homepage       'http://padre.perlide.org/';
bugtracker     'http://padre.perlide.org/';
repository     'http://svn.perlide.org/padre/trunk/Padre-Plugin-XML';

is_padre_plugin; # authors: Install Module::Install::PadrePlugin

WriteAll;
