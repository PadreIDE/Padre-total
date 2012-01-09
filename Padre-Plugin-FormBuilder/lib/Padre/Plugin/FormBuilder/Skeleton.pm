package Padre::Plugin::FormBuilder::Skeleton;

# Project skeleton builder

use 5.008;
use strict;
use warnings;
use File::Spec   ();
use Params::Util ();

our $VERSION = '0.04';

sub new {
	my $class = shift;
	my $self  = bless { @_ }, $class;

	# Check params
	unless ( $self->root and -d $self->root and -w $self->root ) {
		die "Missing or invalid root path";
	}
	unless ( Params::Util::_CLASS($self->name) ) {
		die "Missing or invalid dist name";
	}

	# Initialise the file list
	$self->{files} = { };

	return $self;
}

sub root {
	$_[0]->{root};
}

sub name {
	$_[0]->{name};
}

sub dist {
	my $self = shift;
	my $dist = $self->name;
	$dist =~ s/::/-/g;
	return $dist;
}

sub distdir {
	my $self = shift;
	File::Spec->catdir( $self->root, $self->dist );
}

sub headline {
	File::Spec->catfile( 'lib', split /::/, $_[0]->name ) . '.pm';
}





######################################################################
# Fill the skeleton with files

sub add_file {
	my $self = shift;
	my $path = shift;
	my $code = shift;

	# Save to the file hash with Unix file semantics
	$self->{$path} = $code;

	return 1;
}





######################################################################
# Generate the project to various targets

# Simple naive foreground writer
sub write {
	my $self  = shift;
	my $files = $self->{files};
	my $base  = $self->distdir;

	# Create all of the files
	foreach my $file ( sort keys %$files ) {
		my $path = File::Spec->catfile( $base, $file );
		open( FILE, '>', $path ) or die "open($path): $!";
		print FILE $files->{$file};
		close FILE;
	}

	return 1;
}

1;

# Copyright 2008-2012 The Padre development team as listed in Padre.pm.
# LICENSE
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl 5 itself.
