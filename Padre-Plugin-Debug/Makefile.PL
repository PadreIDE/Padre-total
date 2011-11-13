use inc::Module::Install 1.00;

# Define metadata
name 'Padre-Plugin-Debug';
abstract 'Debug contains Padre Debugger interface v2';
author 'Kevin Dawson <bowtie@cpan.org>';
license 'perl';
perl_version '5.010';

# All from our plugin
all_from 'lib/Padre/Plugin/Debug.pm';
requires_from 'lib/Padre/Plugin/Debug/Main.pm';
requires_from 'lib/Padre/Plugin/Debug/Debugger.pm';
requires_from 'lib/Padre/Plugin/Debug/Panel/Breakpoints.pm';
requires_from 'lib/Padre/Plugin/Debug/Panel/DebugOutput.pm';
requires_from 'lib/Padre/Plugin/Debug/Panel/DebugVariable.pm';


# Padre version, should match that of the latest version, used in padre_interfaces,
requires 'Padre' => '0.91';

# required modules from CPAN
requires 'Debug::Client' => '0.13_08';
requires 'Data::Printer' => '0.24';

# Optional if you have used the share directory
# install_share;

WriteAll;
