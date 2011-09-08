use strict;
use warnings;
use inc::Module::Install;

name           'Padre-Plugin-XS';
license        'perl';
author         'Steffen Mueller <smueller@cpan.org>';
author         'Ahmad M. Zawawi <ahmad.zawawi@gmail.com>';
all_from       'lib/Padre/Plugin/XS.pm';
requires       'Padre'                   => '0.90';
requires       'Perl::APIReference'      => '0.04';
test_requires  'Test::More'              => '0.47';
no_index       'directory'               => qw{ t xt eg share inc};
homepage       'http://padre.perlide.org/';
bugtracker     'http://padre.perlide.org/';
repository     'http://svn.perlide.org/padre/trunk/Padre-Plugin-XS';

is_padre_plugin; # authors: Install Module::Install::PadrePlugin

WriteAll;
