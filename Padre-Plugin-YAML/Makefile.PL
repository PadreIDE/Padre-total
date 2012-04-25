#use 5.010001;
use strict;
use warnings;
use inc::Module::Install;

name 'Padre-Plugin-YAML';
all_from 'lib/Padre/Plugin/YAML.pm';

requires 'Padre'     => '0.96';
requires 'Try::Tiny' => '0.11';

if ( $^O =~ /Win32/i ) {
	requires 'YAML' => '0.80';
} else {
	requires 'YAML::XS' => '0.38';
}

test_requires 'Test::More' => '0.88';
test_requires 'File::Temp' => '0.22';

no_index 'directory' => qw{ t eg share inc};
homepage 'http://padre.perlide.org/trac/wiki/PadrePluginYAML';
bugtracker 'http://padre.perlide.org/';
repository 'http://svn.perlide.org/padre/trunk/Padre-Plugin-YAML';

install_share_with_mofiles;

WriteAll;
