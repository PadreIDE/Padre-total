use strict;
use warnings;
use inc::Module::Install;

name 'Padre-Plugin-Moose';
all_from 'lib/Padre/Plugin/Autoformat.pm';

requires 'Padre'           => '0.94';
requires 'File::Basename'        => '0',
requires 'File::Spec::Functions' => '0',
requires 'Padre'                 => '0.90',
requires 'Text::Autoformat'      => '0'
test_requires 'Test::More' => '0.88';

no_index 'directory' => qw{ t share inc};
homepage 'http://padre.perlide.org/trac/wiki/PadrePluginAutoformat';
bugtracker 'http://padre.perlide.org/';
repository 'http://svn.perlide.org/padre/trunk/Padre-Plugin-Autoformat';

install_share_with_mofiles;

WriteAll;
