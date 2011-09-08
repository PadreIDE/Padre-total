use strict;
use warnings;
use inc::Module::Install;

name           'Padre-Plugin-Catalyst';
license        'perl';
author         'Breno G. de Oliveira <garu@cpan.org>';
author         'Ahmad M. Zawawi <ahmad.zawawi@gmail.com>';
all_from       'lib/Padre/Plugin/Catalyst.pm';
requires       'Padre'                   => '0.90';
requires       'Cwd'                     => 0;
requires       'File::Spec'              => 0;
requires       'Catalyst::Devel'         => '1.0';
requires       'Catalyst::Runtime'       => '5.70';
requires       'File::Which'             => '0.05';
test_requires  'Test::More'              => '0.47';
no_index       'directory'               => qw{ t xt eg share inc};
homepage       'http://padre.perlide.org/';
bugtracker     'http://padre.perlide.org/';
repository     'http://svn.perlide.org/padre/trunk/Padre-Plugin-Catalyst';

is_padre_plugin; # authors: Install Module::Install::PadrePlugin

WriteAll;
