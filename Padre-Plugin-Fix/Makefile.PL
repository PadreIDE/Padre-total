use strict;
use warnings;
use inc::Module::Install;

name 'Padre-Plugin-Fix';
all_from 'lib/Padre/Plugin/Fix.pm';

requires 'Padre' => '0.94';
requires 'Moose' => '2.0402';

test_requires 'Test::More' => '0.88';

no_index 'directory' => qw{ t share inc};
homepage 'http://padre.perlide.org/trac/wiki/PadrePluginFix';
bugtracker 'http://padre.perlide.org/';
repository 'http://svn.perlide.org/padre/trunk/Padre-Plugin-Fix';

install_share_with_mofiles;

WriteAll;
