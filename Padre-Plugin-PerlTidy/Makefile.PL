use strict;
use warnings;
use inc::Module::Install;

name           'Padre-Plugin-PerlTidy';
license        'perl';
author         'Brian Cassidy <bricas@cpan.org>';
all_from       'lib/Padre/Plugin/PerlTidy.pm';
requires       'Padre'      => '0.92';
requires       'Perl::Tidy' => '20101217';
test_requires  'Test::More' => '0.42';

no_index       'directory'               => qw{ t xt eg share inc};
homepage       'http://padre.perlide.org/';
bugtracker     'http://padre.perlide.org/';
repository     'http://svn.perlide.org/padre/trunk/Padre-Plugin-PerlTidy';

is_padre_plugin; # authors: Install Module::Install::PadrePlugin

WriteAll;
