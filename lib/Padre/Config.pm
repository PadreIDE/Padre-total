package Padre::Config;

use 5.008;
use strict;
use warnings;
use Storable      ();
use File::Path    ();
use File::Spec    ();
use File::HomeDir ();
use Params::Util  qw{ _STRING _ARRAY };
use YAML::Tiny    ();

our $VERSION = '0.11';





#####################################################################
# Class-Level Functionality

my $DEFAULT_DIR = File::Spec->catfile(
	($ENV{PADRE_HOME} ? $ENV{PADRE_HOME} : File::HomeDir->my_data),
	'.padre'
);

sub default_dir {
	my $dir = $DEFAULT_DIR;
	unless ( -e $dir ) {
		mkdir $dir or
		die "Cannot create config dir '$dir' $!";
	}

	return $dir;
}

sub default_yaml {
	File::Spec->catfile(
		$_[0]->default_dir,
		'config.yml',
	);
}

sub default_db {
   File::Spec->catfile(
		$_[0]->default_dir,
		'config.db',
	);
}

sub default_plugin_dir {
	my $pluginsdir = File::Spec->catdir(
		$_[0]->default_dir,
		'plugins',
	);
	my $plugins_full_path = File::Spec->catdir(
		$pluginsdir, 'Padre', 'Plugin'
	);
	unless ( -e $plugins_full_path) {
		File::Path::mkpath($plugins_full_path) or
		die "Cannot create plugins dir '$plugins_full_path' $!";
	}

	return $pluginsdir;
}





#####################################################################
# Constructor and Serialization

sub new {
	my $class = shift;
	my $self  = bless { @_ }, $class;

	# Main window geometry
	$self->{host}->{main_height}    ||= Wx::wxDefaultSize()->height;
	$self->{host}->{main_width}     ||= Wx::wxDefaultSize()->width;
	$self->{host}->{main_left}      ||= Wx::wxDefaultPosition()->x;
	$self->{host}->{main_top}       ||= Wx::wxDefaultPosition()->y;
	$self->{host}->{main_maximized} ||= 0;

	# Files that were previously open (and can be still)
	unless ( _ARRAY($self->{host}->{main_files}) ) {
		$self->{host}->{main_files} = [];
	}
	$self->{host}->{main_files} = [
		grep { -f $_ and -r _ }
		@{ $self->{host}->{main_files} }
	];

	# When they want to run an arbitrary command
	$self->{host}->{run_command}    ||= '';

	# Number of modules to display when searching for documentation
	$self->{pod_maxlist} ||= 200;
	unless ( defined $self->{pod_minlist} ) {
		$self->{pod_minlist} = 2;
	}

	# startup mode, if no files given on the command line this can be
	#   new        - a new empty buffer
	#   nothing    - nothing to open
	#   last       - the files that were open last time    
	$self->{main_startup}  ||= 'new';

	# Look and feel preferences
	$self->{main_statusbar}           ||= 1;
	$self->{editor_tabwidth}          ||= 4;
	$self->{editor_linenumbers}       ||= 0;
	$self->{editor_eol}               ||= 0;
	$self->{editor_indentationguides} ||= 0;
	unless ( defined $self->{editor_calltips} ) {
		$self->{editor_calltips} = 1;
	}

	# When running a script from the application some of the files might have not been saved yet.
	# There are several option what to do before running the script
	# none - don's save anything
	# same - save the file in the current buffer
	# all_files - all the files (but not buffers that have no filenames)
	# all_buffers - all the buffers even if they don't have a name yet
	$self->{run_save}        ||= 'same';

	# Search and replace recent values
	$self->{search_terms}  ||= [];
	$self->{replace_terms} ||= [];

	# Various things that should probably be in the database
	$self->{bookmarks}       ||= {};
	$self->{projects}        ||= {};
	$self->{current_project} ||= '';

	# By default we have an empty plugins configuration
	$self->{plugins}      ||= {};

	# By default, don't enable experimental features
	$self->{experimental} ||= 0;

	return $self;
}

# Write a null config, then read it back in
sub create {
	my $class = shift;
	my $file  = shift;

	# Save a null configuration
	YAML::Tiny::DumpFile( $file, {} );

	# Now read it (and the host config) back in
	return $class->read( $file );
}

sub read {
	my $class = shift;

	# Check the file
	my $file = shift;
	unless ( defined $file and -f $file and -r $file ) {
		return;
	}

	# Load the user configuration
	my $hash = YAML::Tiny::LoadFile($file);
	return unless ref($hash) eq 'HASH';

	# Load the host configuration
	my $host = Padre::DB->hostconf_read;
	return unless ref($hash) eq 'HASH';

	# Expand a few things
	if ( defined _STRING($host->{main_files}) ) {
		$host->{main_files} = [
			 split /\n/, $host->{main_files}
		];
	}

	# Merge and create the configuration
	return $class->new( %$hash, host => $host );
}

sub write {
	my $self = shift;

	# Clone and remove the bless
	my $copy = Storable::dclone( +{ %$self } );

	# Clean out some internals
	my $bookmarks = $self->{bookmarks};
	foreach my $key ( keys %$bookmarks ) {
		delete $bookmarks->{$key}->{pageid};
	}

	# Serialize some values
	$copy->{host}->{main_files} = join( "\n", @{$copy->{host}->{main_files}} );

	# Save the host configuration
	Padre::DB->hostconf_write( delete $copy->{host} );

	# Save the user configuration
	YAML::Tiny::DumpFile( $_[0], $copy );

	return 1;
}

1;
