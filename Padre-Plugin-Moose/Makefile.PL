use strict;
use warnings;
use inc::Module::Install;

name 'Padre-Plugin-Moose';
license 'perl';
author 'Ahmad M. Zawawi <ahmad.zawawi@gmail.com>';
all_from 'lib/Padre/Plugin/Moose.pm';

requires 'Padre'            => '0.94';
requires 'Moose'            => '2.0402';
requires 'namespace::clean' => '0.22';
requires 'YAML::Tiny'       => '1.32';
requires 'File::ShareDir'   => '1.00';
test_requires 'Test::More'  => '0.47';

no_index 'directory' => qw{ t xt eg share inc};
homepage 'http://padre.perlide.org/trac/wiki/PadrePluginMoose';
bugtracker 'http://padre.perlide.org/';
repository 'http://svn.perlide.org/padre/trunk/Padre-Plugin-Moose';

install_share_with_mofiles;

WriteAll;
