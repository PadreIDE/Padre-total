use strict;
use warnings;
use inc::Module::Install 1.06;

name 'Padre-Plugin-YAML';
all_from 'lib/Padre/Plugin/YAML.pm';

requires 'Padre'     => '0.96';
requires 'Try::Tiny' => '0.11';

if ( $^O =~ /Win32/i ) {
	requires 'YAML' => '0.80';
} else {
	requires 'YAML::XS' => '0.38';
}

test_requires 'Test::More'          => '0.92';
test_requires 'File::Temp'          => '0.22';
test_requires 'Test::Pod'           => '1.45';
test_requires 'Test::Pod::Coverage' => '1.08';

no_index 'directory' => qw{ t xt eg share inc};
homepage 'http://padre.perlide.org/trac/wiki/PadrePluginYAML';
bugtracker 'http://padre.perlide.org/';
repository 'http://svn.perlide.org/padre/trunk/Padre-Plugin-YAML';

install_share_with_mofiles;

WriteAll;
