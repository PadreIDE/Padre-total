package Padre::Config;

use 5.008;
use strict;
use warnings;
use File::Path    ();
use File::Spec    ();
use File::HomeDir ();
use YAML::Tiny    ();

our $VERSION = '0.09';



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

    # Apply defaults
    # Number of modules to display when searching for documentation
    $self->{DISPLAY_MAX_LIMIT} ||= 200;
    unless ( defined $self->{DISPLAY_MIN_LIMIT} ) {
        $self->{DISPLAY_MIN_LIMIT} = 2;
    }

    # size of the main window
    $self->{main}->{height}    ||= Wx::wxDefaultSize()->height;
    $self->{main}->{width}     ||= Wx::wxDefaultSize()->width;
    $self->{main}->{left}      ||= Wx::wxDefaultPosition()->x;
    $self->{main}->{top}       ||= Wx::wxDefaultPosition()->y;

    # Is the window maximized
    $self->{main}->{maximized} ||= 0;

    # startup mode, if no files given on the command line this can be
    #   new        - a new empty buffer
    #   nothing    - nothing to open
    #   last       - the files that were open last time    
    $self->{startup}           ||= 'new';
    $self->{search_terms}      ||= [];
    $self->{replace_terms}     ||= [];
    $self->{command_line}      ||= '';
    $self->{bookmarks}         ||= {};
    #if (not $self->{bookmarks}) {
    #   $self->{bookmarks}{$_} = undef for ('a'..'z');
    #}

    # When running a script from the application some of the files might have not been saved yet.
    # There are several option what to do before running the script
    # none - don's save anything
    # same - save the file in the current buffer
    # all_files - all the files (but not buffers that have no filenames)
    # all_buffers - all the buffers even if they don't have a name yet
    $self->{save_on_run}        ||= 'same';
    $self->{show_line_numbers}  ||= 0;
    $self->{show_eol}           ||= 0;
    $self->{projects}           ||= {};
    $self->{current_project}    ||= '';
    $self->{editor}->{tab_size} ||= 8;
    unless ( exists $self->{editor}->{show_calltips} ) {
        $self->{editor}->{show_calltips} = 1;
    }

    # by default, we have an empty plugins configuration
    $self->{plugins}           ||= {};

    # By default, don't enable experimental features
    $self->{experimental} ||= 0;

    return $self;
}

sub read {
    my $class = shift;

    # Check the file
    my $file = shift;
    unless ( defined $file and -f $file and -r $file ) {
        return;
    }

    # Load the config
    my $hash = YAML::Tiny::LoadFile($file);
    return unless ref($hash) eq 'HASH';
    return $class->new( %$hash );
}

sub write {
    my $self = shift;

    my %hash = %{ $self };
    delete $self->{bookmarks}{$_}{pageid} for keys %{$self->{bookmarks}};
    YAML::Tiny::DumpFile( shift, \%hash );

    return 1;
}

1;
