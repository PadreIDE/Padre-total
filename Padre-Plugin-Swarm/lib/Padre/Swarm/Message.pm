package Padre::Swarm::Message;
use strict;
use warnings;

use Class::XSAccessor
	accessors => {
		#entity => 'entity',
		title  => 'title',
		body   => 'body',
		type   => 'type',
		to     => 'to',
		from   => 'from',
	};
	

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
to from and title are strings
type is always a string and may be used to subclass by registration
subclasses must not mutate  title,type,from,to 
body considered scalar bytes
  
  
=head1 entity

transport entity origin

=cut

sub entity {
	my $self = shift;
	my $client_address;
	my $channel;
	my $resource;
	
	
}
1;
