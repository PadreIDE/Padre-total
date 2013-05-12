use strict;
use warnings;
use inc::Module::Install 1.06;

name 'Padre-Plugin-YAML';
all_from 'lib/Padre/Plugin/YAML.pm';

perl_version '5.010001';

requires 'Padre'     => '0.96';
requires 'Try::Tiny' => '0.12';

if ( $^O =~ /Win32/i ) {
	requires 'YAML' => '0.84';
} else {
	requires 'YAML::XS' => '0.41';
}

requires 'constant'  => '1.27';
requires 'parent'    => '0.225';

test_requires 'File::Temp'     => '0.2301';
test_requires 'Test::More'     => '0.98';
test_requires 'Test::Requires' => '0.06';

recommends 'Test::Pod'           => '1.48';
recommends 'Test::Pod::Coverage' => '1.08';

no_index 'directory' => qw{ inc share t xt };

homepage 'http://padre.perlide.org/trac/wiki/PadrePluginYAML';
bugtracker 'http://padre.perlide.org/';
repository 'http://svn.perlide.org/padre/trunk/Padre-Plugin-YAML';

install_share_with_mofiles;

WriteAll;

