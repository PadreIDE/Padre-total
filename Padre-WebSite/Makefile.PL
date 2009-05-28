use 5.008005;
use strict;
use inc::Module::Install 0.77;



#####################################################################
# Normal Boring Commands

# NOTE: Core modules that aren't dual-life should always have a version of 0

name           'Padre-WebSite';
license        'perl';
author         'Gabor Szabo';
all_from       'lib/Padre/WebSite.pm';
requires       'perl'                     => '5.008005';
requires       'CGI'                      => 0;
requires       'DBD::SQLite'              => '1.10';
requires       'DBI'                      => '1.58';
requires       'Digest::MD5'              => 0;
requires       'FindBin'                  => 0;
requires       'YAML::Tiny'               => '1.32';
test_requires  'Test::More'               => '0.47';
test_requires  'Test::Most'               => '0.21';
test_requires  'Test::Snapshots'          => '0.03';
test_requires  'Test::NoWarnings'         => '0.084';

no_index       'directory'                => qw{ t xt eg share inc privinc };
homepage       'http://padre.perlide.org/';
bugtracker     'http://padre.perlide.org/';
repository     'http://svn.perlide.org/padre/trunk/Padre-WebSite/';
#MailingList    'http://mail.perlide.org/mailman/listinfo/padre-dev';
install_script 'script/collector.pl';


WriteAll;
