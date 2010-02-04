use strict;
use warnings;
use inc::Module::Install;

name           'Padre-Plugin-Tasks';
license        'perl';
author         'Gabor Szabo <szabgab@gmail.com>';
all_from       'lib/Padre/Plugin/Tasks.pm';
requires       'Padre'                   => '0.25';
requires       'Wx::Perl::Dialog'        => '0.04';
requires       'Wx::TreeListCtrl'        => '0.06';
test_requires  'Test::More'              => '0.47';
no_index       'directory'               => qw{ t xt eg share inc};
homepage       'http://padre.perlide.org/';
bugtracker     'http://padre.perlide.org/';
repository     'http://svn.perlide.org/padre/trunk/Padre-Plugin-Tasks';

is_padre_plugin; # authors: Install Module::Install::PadrePlugin

#install_share_with_mofiles; # install Locale::Msgfmt

WriteAll;
