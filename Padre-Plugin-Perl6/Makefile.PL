use strict;
use warnings;
use inc::Module::Install;

name 'Padre-Plugin-Perl6';
license 'perl';

author 'Gabor Szabo L<http://szabgab.com/>';
author 'Ahmad M. Zawawi <ahmad.zawawi@gmail.com>';

all_from 'lib/Padre/Plugin/Perl6.pm';
requires_from 'lib/Padre/Plugin/Perl6/Colorizer.pm';
requires_from 'lib/Padre/Plugin/Perl6/Document.pm';
requires_from 'lib/Padre/Plugin/Perl6/Help.pm';
requires_from 'lib/Padre/Plugin/Perl6/Outline.pm';
requires_from 'lib/Padre/Plugin/Perl6/Preferences.pm';
requires_from 'lib/Padre/Plugin/Perl6/QuickFix.pm';
requires_from 'lib/Padre/Plugin/Perl6/StdColorizer.pm';
requires_from 'lib/Padre/Plugin/Perl6/StdColorizerTask.pm';
requires_from 'lib/Padre/Plugin/Perl6/Syntax.pm';
requires_from 'lib/Padre/Plugin/Perl6/Util.pm';

requires 'Padre'                    => '0.91';
requires 'Digest::MD5'              => 0;
requires 'Class::XSAccessor'        => '1.02';
requires 'App::Grok'                => '0.22';
requires 'File::Temp'               => 0;
requires 'URI'                      => '1.37';
requires 'Cwd'                      => 0;
requires 'File::Basename'           => 0;
requires 'File::Spec'               => 0;
requires 'Scalar::Util'             => 0;
requires 'Win32'                    => 0;
requires 'Win32::Process'           => 0;
requires 'YAML::XS'                 => 0;
requires 'Params::Util'             => 0;
requires 'File::Which'              => '0.05';
requires 'Syntax::Highlight::Perl6' => '0.87';
requires 'Perl6::Doc'               => '0.45';

test_requires 'Test::More' => '0.47';
no_index 'directory'       => qw{ t xt eg share inc};

homepage 'http://padre.perlide.org/';
bugtracker 'http://padre.perlide.org/';
repository 'http://svn.perlide.org/padre/trunk/Padre-Plugin-Perl6';

is_padre_plugin; # authors: Install Module::Install::PadrePlugin

WriteAll;
