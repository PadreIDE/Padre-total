use strict;
use warnings;
use inc::Module::Install;

name           'Padre-Plugin-PerlCritic';
license        'perl';
author         'Kaare Rasmussen <kaare@cpan.org>';
author         'Ahmad M. Zawawi <ahmad.zawawi@gmail.com>';
all_from       'lib/Padre/Plugin/PerlCritic.pm';
requires       'Padre'                   => '0.80';
requires       'Perl::Critic'            => 0;
test_requires  'Test::More'              => '0.47';
no_index       'directory'               => qw{ t xt eg share inc};
homepage       'http://padre.perlide.org/';
bugtracker     'http://padre.perlide.org/';
repository     'http://svn.perlide.org/padre/trunk/Padre-Plugin-PerlCritic';

is_padre_plugin; # authors: Install Module::Install::PadrePlugin

WriteAll;
