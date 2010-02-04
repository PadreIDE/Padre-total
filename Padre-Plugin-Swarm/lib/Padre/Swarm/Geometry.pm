package Padre::Swarm::Geometry;

use strict;
use warnings;
use Params::Util qw( _INSTANCE );
use Graph;
use Graph::Directed;
use JSON::XS;
use Class::XSAccessor 
    accessors => {
	graph => 'graph',
    };
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

sub new {
	my $class = shift;
	my %args = @_;
	$args{graph} ||= new Graph::Directed
	    unless _INSTANCE( $args{graph}, 'Graph::Directed' );
	
	return bless \%args, ref($class) || $class;
}

sub plugin {
    return Padre::Plugin::Swarm->instance;
}

sub get_users {
	my $self = shift;
	return $self->graph->successors( '~identity' );
	
}

sub On_SwarmMessage {
    my ($self,$message) = @_;
    my $handler = 'accept_'  . $message->{type};
    eval { $self->$handler($message) } if $self->can($handler) ;
    warn "Geometry handler error - $@" if $@;
    
}

sub accept_promote {
	my $self = shift;
	my $message = shift;
	$self->graph->add_edge( '~service' => $message->{service} );
	#$self->graph->add_edge( $message->{service} , $message->{from} );
	# just in case
	$self->graph->add_edge( '~identity' => $message->{from} );
	
	if ($message->{resource}) {
		$self->graph->add_edge( 
			$message->{from} , 
			':' . $message->{resource} );
	}
	

}

sub accept_destroy {
	my $self = shift;
	my $message = shift;
        return unless $message->{resource};
	$self->graph->delete_edge( $message->{from} ,
		':' . $message->{resource}
	);
		
	$self->graph->delete_edge( ':' . $message->{resource} ,
		$message->{service}
	);
	
}


sub accept_disco {
	my $self = shift;
	my $message = shift;
	my $g = $self->graph;
	# TODO - if this disco is targeted to us do something interesting
}

sub accept_announce {
	my $self = shift;
	my $message = shift;
	$self->graph->add_edge( '~identity' => $message->{from} );
	if ( exists $message->{resource} ) {
		$self->graph->add_edge( 
		    $message->{from} ,
		    $message->{resource},
		)
	}
	
}

sub accept_leave {
	my $self = shift;
	my $message = shift;
	my @s = $self->graph->successors( $message->{from} );
	$self->graph->delete_vertex( $_ )
	    for @s, $message->{from};
	
	
}


sub TO_JSON {
	
}

sub FROM_JSON {
	
}

1;
