package Padre::Plugin::Ecliptic::OpenInExplorerAction;

use strict;
use warnings;

# package exports and version
our $VERSION = '0.09';
our @EXPORT_OK = ();

# module imports
use Padre::Wx ();
use Padre::Util   ('_T');

# accessors
use Class::XSAccessor accessors => {
	_plugin            => '_plugin',             # Plugin object
};

# -- constructor
sub new {
	my ($class, $plugin) = @_;
	
	my $self = bless {}, $class;
	$self->_plugin($plugin);

	return $self;
}

#
# private method for executing a process without waiting
#
sub _execute {
	my ($self, $exe_name, $cmd_args) = @_;
	my $result = undef;
	my $cmd = File::Which::which($exe_name);
	if(-e $cmd) {
		require IPC::Open2;
		my $pid = IPC::Open2::open2(0, 0, $cmd, $cmd_args);
	} else {
		$result = _T("Failed to execute process\n");
	}
	return $result;
}
	
#
# For the current "saved" Padre document,
# On win32, selects it in Windows Explorer
# On linux, opens the containing folder for it
#
sub open_in_explorer {
	my $self = shift;

	my $main = $self->_plugin->main;
	my $filename = $main->current->filename;
	if(not defined $filename) {
		Wx::MessageBox( _T("No filename"), _T('Error'), Wx::wxOK, $main, );
		return;
	}

	require File::Which;

	my $error = undef;
	if($^O =~ /win32/i) {
		# In windows, simply execute: explorer.exe /select,"$filename"
		$filename =~ s/\//\\/g;
		$error = $self->_execute('explorer.exe', "/select,\"$filename\"");
	} elsif($^O =~ /linux|bsd/i) {
		if( defined $ENV{KDEDIR} ) {
			# In KDE, execute: kfmclient exec $filename
			$error = $self->_execute('kfmclient', "exec $filename");
		} elsif( defined $ENV{GNOME_DESKTOP_SESSION_ID} ) {
			# In Gnome, execute: nautilus --nodesktop --browser $filename
			$error = $self->_execute('nautilus', "--nodesktop --browser $filename");
		} else {
			$error = "Could not find KDE or GNOME";
		}
	} else {
		#Unsupported Operating system.
		$error = "Unsupported operating system: '$^O'";
	}

	if(defined $error) {
		Wx::MessageBox( $error, _T("Error"), Wx::wxOK, $main, );
	}

	return;
}

1;