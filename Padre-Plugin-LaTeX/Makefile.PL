use strict;
use warnings;
use inc::Module::Install;

name           'Padre-Plugin-LaTeX';
license        'perl';
author         'Zeno Gantner <zenog@cpan.org>';
author         'Ahmad M. Zawawi <ahmad.zawawi@gmail.com>';
all_from       'lib/Padre/Plugin/LaTeX.pm';
requires       'Padre'                   => '0.90';
requires       'File::Spec::Functions'   => 0;
requires       'File::Which'             => 0;
test_requires  'Test::More'              => '0.47';
no_index       'directory'               => qw{ t xt eg share inc};
homepage       'http://padre.perlide.org/';
bugtracker     'http://padre.perlide.org/';
repository     'http://svn.perlide.org/padre/trunk/Padre-Plugin-LaTeX';

is_padre_plugin; # authors: Install Module::Install::PadrePlugin

WriteAll;
