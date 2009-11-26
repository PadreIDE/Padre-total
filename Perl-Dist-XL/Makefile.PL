use 5.008005;
use strict;
use inc::Module::Install 0.86;


#####################################################################
# Normal Boring Commands

# NOTE: Core modules that aren't dual-life should always have a version of 0

name           'Perl-Dist-XL';
license        'perl';
author         'Gabor Szabo';
all_from       'lib/Perl/Dist/XL.pm';
requires       'perl'                     => '5.008005';
requires       'Carp'                     => 0;
requires       'Cwd'                      => 0;
requires       'CPAN::Mini'               => 0;
requires       'Data::Dumper'             => 0;
#requires       'DBD::SQLite'              => '1.10';
#requires       'DBI'                      => '1.58';
requires       'File::Basename'           => 0;
requires       'File::Copy'               => 0;
#requires       'File::Copy::Recursive'    => '0.37';
#requires       'File::Find::Rule'         => '0.30';
requires       'File::HomeDir'            => '0.84';
requires       'File::Path'               => 0;
#requires       'File::ShareDir'           => '1.00';
#requires       'File::Spec'               => '3.2701';
requires        'File::Temp'              => 0;
#requires       'File::Which'              => '0.05';
#requires       'FindBin'                  => 0;
requires       'Getopt::Long'             => 0;
test_requires  'LWP'                      => '0'; # LWP::Simple
test_requires  'Test::More'               => '0.47';

no_index       'directory'                => qw{ t xt eg share inc };
homepage       'http://padre.perlide.org/';
bugtracker     'http://padre.perlide.org/';
repository     'http://svn.perlide.org/padre/trunk/Perl-Dist-XL/';
install_script 'script/perldist_xl.pl';
install_share;

WriteAll;
