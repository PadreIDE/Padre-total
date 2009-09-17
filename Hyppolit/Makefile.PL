use 5.008005;
use strict;
use inc::Module::Install 0.77;


name           'Hyppolit';
license        'perl';
author         'Gabor Szabo';
all_from       'lib/Hyppolit.pm';
requires       'perl'                                  => '5.008001';
requires       'POE'                                   => '1.003';
requires       'POE::Component::IRC::State'            => '2.52';
requires       'POE::Component::IRC::Plugin::AutoJoin' => '1.2';
requires       'YAML::Syck'                            => '1.0';

no_index       'directory'                => qw{ t xt eg share inc privinc };
#homepage       'http://padre.perlide.org/';
#bugtracker     'http://padre.perlide.org/';
#repository     'http://svn.perlide.org/padre/trunk/Padre/';
# MailingList  'http://mail.perlide.org/mailman/listinfo/padre-dev';
install_script 'script/hyppolit.pl';


WriteAll;
