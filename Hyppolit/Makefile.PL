use v5.10;
use strict;
use inc::Module::Install 1.06;


name 'Hyppolit';
license 'perl';
author 'Gabor Szabo';
all_from 'lib/Hyppolit.pm';
requires 'perl'                       => '5.010001';
requires 'POE'                        => '1.354';
requires 'POE::Component::IRC::State' => '6.78';
requires 'YAML::XS'                   => '0.38';
requires 'Data::Printer'              => '0.3';
requires 'DBD::SQLite'                => '1.25';
requires 'DBI'                        => '1.609';
requires 'IRC::Utils'                 => '0';
no_index 'directory'                  => qw{ t xt eg share inc privinc };

#homepage       'http://padre.perlide.org/';
#bugtracker     'http://padre.perlide.org/';
#repository     'http://svn.perlide.org/padre/trunk/Padre/';
# MailingList  'http://mail.perlide.org/mailman/listinfo/padre-dev';
install_script 'script/hyppolit.pl';


WriteAll;
