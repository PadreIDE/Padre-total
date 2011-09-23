use inc::Module::Install 1.01;

# Define metadata
abstract 'Perl only solutions for diff and patch in Padre::Plugin:Patch';

# All from our plugin
all_from 'lib/Padre/Plugin/Patch.pm';
requires_from 'lib/Padre/Plugin/Patch/Main.pm';

# Padre version, should match that of the latest version, used in padre_interfaces,
requires 'Padre' => '0.89';

# required modules from CPAN
requires 'File::Slurp'    => '9999.19';
requires 'Text::Diff'     => '1.41';
requires 'Text::Patch'    => '1.8';
requires 'Data::Printer'  => '0.22';
requires 'Sort::Versions' => '1.5';
requires 'File::Find'     => '1.19';

# Optional if you have used the share directory
#install_share;

WriteAll;
