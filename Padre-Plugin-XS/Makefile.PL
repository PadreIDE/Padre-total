use strict;
use warnings;
use inc::Module::Install;

name 'Padre-Plugin-XS';
all_from 'lib/Padre/Plugin/XS.pm';

requires       'Padre'                   => '0.94';
requires       'Perl::APIReference'      => '0.04';
test_requires  'Test::More'              => '0.88';

no_index 'directory' => qw{ t share inc};
homepage 'http://padre.perlide.org/trac/wiki/PadrePluginXS';
bugtracker 'http://padre.perlide.org/';
repository 'http://svn.perlide.org/padre/trunk/Padre-Plugin-XS';

install_share_with_mofiles;

WriteAll;