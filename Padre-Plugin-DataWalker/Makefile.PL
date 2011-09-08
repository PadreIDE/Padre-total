use strict;
use warnings;
use inc::Module::Install;

name           'Padre-Plugin-DataWalker';
license        'perl';
author         'Steffen Mueller <smueller@cpan.org>';
author         'Ahmad M. Zawawi <ahmad.zawawi@gmail.com>';
all_from       'lib/Padre/Plugin/DataWalker.pm';
requires       'Padre'                   => '0.90';
requires       'Wx::Perl::DataWalker'    => '0.02';
requires       'YAML::XS'                => 0;
test_requires  'Test::More'              => '0.47';
no_index       'directory'               => qw{ t xt eg share inc};
homepage       'http://padre.perlide.org/';
bugtracker     'http://padre.perlide.org/';
repository     'http://svn.perlide.org/padre/trunk/Padre-Plugin-DataWalker';

is_padre_plugin; # authors: Install Module::Install::PadrePlugin

WriteAll;
