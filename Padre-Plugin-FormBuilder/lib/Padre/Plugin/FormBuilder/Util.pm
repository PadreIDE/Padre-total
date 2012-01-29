package Padre::Plugin::FormBuilder::Util;

# Common utility functions for FormBuilder

use 5.008;
use strict;
use warnings;
use File::Spec   ();
use Params::Util ();

our $VERSION = '0.05';

sub current_fbp {
	my $current = shift;
	my $project = $current->project;
	unless ( Params::Util::_INSTANCE($project, 'Padre::Project::Perl') ) {
		return undef;
	}
	return project_fbp($project);
}

sub project_fbp {
	my $project = shift;
	my $root    = $project->root;

	# Look for a single root .fbp file
	opendir( DIRECTORY, $root ) or return;
	my @files = grep { /\.fbp$/i } readdir( DIRECTORY );
	close( DIRECTORY );

	# There will hopefully only be a single fbp file
	if ( @files == 1 ) {
		return File::Spec->catfile( $project->root );
	} else {
		return undef;
	}
}

1;

# Copyright 2008-2012 The Padre development team as listed in Padre.pm.
# LICENSE
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl 5 itself.
