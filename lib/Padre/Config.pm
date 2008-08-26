package Padre::Config;

use 5.008;
use strict;
use warnings;
use YAML::Tiny;

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
    $self->{main}->{height} ||= 600;
    $self->{main}->{width}  ||= 700;

    # Is the window maximized
    $self->{main}->{maximized} ||= 0;

    # startup mode, if no files given on the command line this can be
    #   new        - a new empty buffer
    #   nothing    - nothing to open
    #   last       - the files that were open last time    
    $self->{startup} ||= 'new';

    unless ( defined $self->{search_terms} ) {
        $self->{search_terms} = [];
    }
    if ($self->{search_term}) {
       $self->{search_terms} = [ delete $self->{search_term} ]
    }

    $self->{command_line}      ||= '';
    # When running a script from the application some of the files might have not been saved yet.
    # There are several option what to do before running the script
    # none - don's save anything
    # same - save the file in the current buffer
    # all_files - all the files (but not buffers that have no filenames)
    # all_buffers - all the buffers even if they don't have a name yet
    $self->{save_on_run}       ||= 'same';
    $self->{show_line_numbers} ||= 0;
    $self->{show_eol}          ||= 0;
    $self->{projects}          ||= {};
    $self->{current_project}   ||= '';

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
    YAML::Tiny::DumpFile( shift, \%hash );
    return 1;
}

1;
