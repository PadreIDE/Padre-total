use 5.008005;
use strict;
use inc::Module::Install 0.77;

name           'Hyppolit';
license        'perl';
author         'Gabor Szabo';
all_from       'lib/Hyppolit.pm';
requires       'perl'                                  => '5.008001';
requires       'Adam'                                  => '0.04';
requires       'DBD::SQLite'                           => '1.25';
requires       'DBI'                                   => '1.609';
requires       'MooseX::Storage'                       => '0.21';
requires       'DBD::SQLite'                           => '1.25';
requires       'DBI'                                   => '1.609';
requires       'Regexp::Common'                        => '2.122';
requires       'POE::Component::IRC::Plugin::FollowTail';
requires       'POE::Component::IRC::Plugin::Logger';
requires       'Module::Pluggable';

no_index       'directory'                => qw{ t xt eg share inc privinc };
#homepage       'http://padre.perlide.org/';
#bugtracker     'http://padre.perlide.org/';
#repository     'http://svn.perlide.org/padre/trunk/Padre/';
# MailingList  'http://mail.perlide.org/mailman/listinfo/padre-dev';
install_script 'script/hyppolit.pl';

WriteAll;
