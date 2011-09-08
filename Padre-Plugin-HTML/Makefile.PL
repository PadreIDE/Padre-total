use strict;
use warnings;
use inc::Module::Install;

name           'Padre-Plugin-HTML';
license        'perl';
author         'Fayland Lam <fayland@gmail.com>';
author         'Ahmad M. Zawawi <ahmad.zawawi@gmail.com>';
all_from       'lib/Padre/Plugin/HTML.pm';
requires       'Padre'                            => '0.81';
requires       'XML::XPath'                       => 0;
requires       'HTML::Tidy'                       => 0;
requires       'WebService::Validator::HTML::W3C' => 0;
test_requires  'Test::More'              => '0.47';
no_index       'directory'               => qw{ t xt eg share inc};
homepage       'http://padre.perlide.org/';
bugtracker     'http://padre.perlide.org/';
repository     'http://svn.perlide.org/padre/trunk/Padre-Plugin-HTML';

is_padre_plugin; # authors: Install Module::Install::PadrePlugin

WriteAll;
