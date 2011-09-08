use strict;
use warnings;
use inc::Module::Install;

name           'Padre-Plugin-ClassSniff';
license        'perl';
author         'Steffen Mueller <smueller@cpan.org>';
author         'Ahmad M. Zawawi <ahmad.zawawi@gmail.com>';
all_from       'lib/Padre/Plugin/ClassSniff.pm';
requires       'Padre'                   => '0.90';
requires       'Class::Sniff'            => '0.08';
test_requires  'Test::More'              => '0.47';
no_index       'directory'               => qw{ t xt eg share inc};
homepage       'http://padre.perlide.org/';
bugtracker     'http://padre.perlide.org/';
repository     'http://svn.perlide.org/padre/trunk/Padre-Plugin-ClassSniff';

is_padre_plugin; # authors: Install Module::Install::PadrePlugin

WriteAll;
