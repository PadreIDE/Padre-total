use strict;
use warnings;
use inc::Module::Install;

name 'Padre-Plugin-WebGUI';
license 'perl';
author 'Patrick Donelan <pdonelan@cpan.org>';

all_from 'lib/Padre/Plugin/WebGUI.pm';
requires_from 'lib/Padre/Plugin/WebGUI/Assets.pm';

requires 'Padre'             => '0.91';
requires 'LWP::UserAgent'    => 0;
requires 'JSON'              => 0;
requires 'Class::XSAccessor' => 0;
requires 'JSON::XS'          => '2.24';

test_requires 'Test::More' => '0.47';
no_index 'directory'       => qw{ t xt eg share inc};

homepage 'http://padre.perlide.org/';
bugtracker 'http://padre.perlide.org/';
repository 'http://svn.perlide.org/padre/trunk/Padre-Plugin-WebGUI';

is_padre_plugin; # authors: Install Module::Install::PadrePlugin

WriteAll;
