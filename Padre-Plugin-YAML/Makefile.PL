use strict;
use warnings;
use inc::Module::Install;

name           'Padre-Plugin-YAML';
license        'perl';
author         'Zeno Gantner <zenog@cpan.org>';
all_from       'lib/Padre/Plugin/YAML.pm';
requires       'Padre'                   => '0.86';
requires       'File::Spec::Functions'   => 0;
test_requires  'Test::More'              => '0.47';
no_index       'directory'               => qw{ t xt eg share inc};
homepage       'http://padre.perlide.org/';
bugtracker     'http://padre.perlide.org/';
repository     'http://svn.perlide.org/padre/trunk/Padre-Plugin-YAML';

is_padre_plugin; # authors: Install Module::Install::PadrePlugin

WriteAll;
