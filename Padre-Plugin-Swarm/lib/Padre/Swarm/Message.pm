package Padre::Swarm::Message;
use base qw( Class::Accessor );

use strict;
use warnings;
__PACKAGE__->mk_accessors(qw(title body type to from));
	
	
sub TO_JSON { 
    ## really should be the canonical identity
    my $self = shift;
    my $ref = {  %$self }       ;
    $ref->{__origin_class} = ref $self;
    $ref;
}


=pod

=head1 NAME

Padre::Swarm::Message - A Swarm message base

=head1 SYNOPSIS

  my ($channel,$entity,$message) = $some_transport->receive_from( $some_channel );
  print $message->title , ' - ' , $message->type;
  if ( $message->type eq 'interesting' ) {
  	# process 
  }  
  
  my $message = 
    Padre::Swarm::Message->new( 
		title => 'Patch ./Changes',
		type  => 'svn:notify',
		from  => 'svn-jabber@example.com',
		to    => 'me@here.com',
		body  => $data ,
    );
  
=head1 DESCRIPTION

At transport layer, a  Swarm message has the attributes to, from, title, body and type.

 title must be a string
 to and from must be L<Padre::Swarm::Identity> instances.
 type is always a string and may be used to subclass by registration
 subclasses must not mutate  title,type,from,to 
 body considered scalar bytes and entirely the problem of the 'type' implementor
  
=cut

1;
