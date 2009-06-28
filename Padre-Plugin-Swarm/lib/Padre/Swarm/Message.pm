package Padre::Swarm::Message;
use strict;
use warnings;

use Class::XSAccessor
	accessors => {
		entity => 'entity',
		message=> 'message',
		type   => 'type',
		to     => 'to',
		
	};
	

=pod

=head1 NAME

Padre::Swarm::Message - A Swarm message base

=head1 SYNOPSIS

  my ($channel,$client,$payload) = $some_transport->receive_from( $some_channel );
  my $message = Padre::Swarm::Message->new( 
		$payload , { client => $client }
  );
  if ( $message ) {
  	  # do something with your message
  }

=cut

1;
