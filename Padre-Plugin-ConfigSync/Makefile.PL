use inc::Module::Install 0.77;

all_from      'lib/Padre/Plugin/ConfigSync.pm';
requires      'File::Spec'    => '3.2701';
requires      'File::Temp'    => 0;
requires      'YAML::Tiny'    => '1.36';
requires      'LWP'           => '5.823';
requires      'Padre::Plugin' => '0.26';
test_requires 'Test::More'    => '0.47';

is_padre_plugin; # authors: Install Module::Install::PadrePlugin

WriteAll;
