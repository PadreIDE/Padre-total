use strict;
use warnings;
use inc::Module::Install 1.06;

name 'Padre-Plugin-XS';
all_from 'lib/Padre/Plugin/XS.pm';

requires 'Modern::Perl'       => '1.20121103';
requires 'Padre'              => '0.98';
requires 'Perl::APIReference' => '0.15';
requires 'YAML::Tiny'         => '1.54';
requires 'parent'             => '0.225';

test_requires 'Test::More' => '0.98';

no_index 'directory' => qw{ inc share t };

homepage 'http://padre.perlide.org/trac/wiki/PadrePluginXS';
bugtracker 'http://padre.perlide.org/';
repository 'http://svn.perlide.org/padre/trunk/Padre-Plugin-XS';

install_share_with_mofiles;

WriteAll;
