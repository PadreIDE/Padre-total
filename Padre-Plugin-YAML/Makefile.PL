use strict;
use warnings;
use inc::Module::Install;

name 'Padre-Plugin-YAML';
all_from 'lib/Padre/Plugin/YAML.pm';

requires 'Padre'                 => '0.94';
requires 'YAML'                  => '0.80';
test_requires 'Test::More'       => '0.88';

no_index 'directory' => qw{ t eg share inc};
homepage 'http://padre.perlide.org/trac/wiki/PadrePluginYAML';
bugtracker 'http://padre.perlide.org/';
repository 'http://svn.perlide.org/padre/trunk/Padre-Plugin-YAML';

install_share_with_mofiles;

WriteAll;
