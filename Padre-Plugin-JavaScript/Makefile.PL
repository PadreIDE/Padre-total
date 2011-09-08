use strict;
use warnings;
use inc::Module::Install;

name           'Padre-Plugin-JavaScript';
license        'perl';
author         'Fayland Lam <fayland@gmail.com>';
author         'Adam Kennedy <adamk@cpan.org>';
author         'Ahmad M. Zawawi <ahmad.zawawi@gmail.com>';
all_from       'lib/Padre/Plugin/JavaScript.pm';
requires       'Padre'                    => '0.80';
requires       'Exporter'                 => 0;
requires       'JavaScript::Beautifier'   => '0.03';
requires       'JavaScript::Minifier::XS' => 0;
requires       'JE'                       => 0;
test_requires  'Test::More'              => '0.47';
no_index       'directory'               => qw{ t xt eg share inc};
homepage       'http://padre.perlide.org/';
bugtracker     'http://padre.perlide.org/';
repository     'http://svn.perlide.org/padre/trunk/Padre-Plugin-JavaScript';

is_padre_plugin; # authors: Install Module::Install::PadrePlugin

WriteAll;
