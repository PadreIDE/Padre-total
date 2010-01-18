package Padre::Swarm::Geometry;

use strict;
use warnings;
use Graph;
use JSON::XS;

our $VERSION = '0.07';

=pod

=head1 NAME

Padre::Swarm::Geometry - represent connectedness between points

=head1 SYNOPSIS

 my $geometry = $message->geometry;
 my $root = $geometry->root;
 if ( $existing_geometry->is_connected( $root->nodeid ) ) {
  
 }
 
 my $nexus = $existing_geometry->get_node('nexus');
 if ( $geometry 

=head1 DESCRIPTION

Vaporware. TODO.

Swarm geometry should be very flexible and fetchable incrementally, a geometry
walker may find a reference to more geometry that is unknown to it, later if 
that geometry arrives in the swarm it may be connected to any existing swarm 
geometries that refer to it.

=cut

sub TO_JSON {
	
}

sub FROM_JSON {
	
}

1;
