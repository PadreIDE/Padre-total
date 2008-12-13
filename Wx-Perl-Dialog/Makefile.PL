use strict;
use inc::Module::Install;

name           'Wx-Perl-Dialog';
license        'perl';
author         'Gabor Szabo';
all_from       'lib/Wx/Perl/Dialog.pm';

requires       'perl'                    => '5.008001';
requires       'Exporter'                => 0;
requires       'File::Copy::Recursive'   => 0;
requires       'File::Spec'              => 0;
requires       'File::Spec::Functions'   => 0;
requires       'FindBin'                 => 0;

requires       'Wx'                      => 0;
requires       'Wx::Perl::ProcessStream' => 0;

test_requires  'Test::More'              => '0.47';
test_requires  'Test::Exception'         => '0.27';
test_requires  'Test::NoWarnings'        => '0.084';
test_requires  'Test::NeedsDisplay'      => '1.05';
no_index       'directory' => [ qw{ t xt eg share inc privinc} ];
install_share  'eg';

homepage       'http://padre.perlide.org/';
bugtracker     'http://padre.perlide.org/';
repository     'http://svn.perlide.org/padre/trunk/Wx-Perl-Dialog';
#mailinglist    'http://mail.perlide.org/mailman/listinfo/padre-dev';
 
WriteAll;
