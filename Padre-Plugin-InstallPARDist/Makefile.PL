use strict;
use warnings;
use inc::Module::Install;

name 'Padre-Plugin-InstallPARDist';
license 'perl';

author 'Steffen Mueller';

all_from 'lib/Padre/Plugin/InstallPARDist.pm';

requires 'Padre'                 => '0.91';
requires 'Carp'                  => 0;
requires 'Cwd'                   => 0;
requires 'Data::Dumper'          => 0;
requires 'ExtUtils::InferConfig' => '1.03';
requires 'ExtUtils::InstallPAR'  => '0.03';
requires 'LWP::Simple'           => '0';

test_requires 'Test::More' => '0.47';
no_index 'directory'       => qw{ t xt eg share inc};

homepage 'http://padre.perlide.org/';
bugtracker 'http://padre.perlide.org/';
repository 'http://svn.perlide.org/padre/trunk/Padre-Plugin-InstallPARDist';

is_padre_plugin; # authors: Install Module::Install::PadrePlugin

WriteAll;
