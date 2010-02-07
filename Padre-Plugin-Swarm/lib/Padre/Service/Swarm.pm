package Padre::Service::Swarm;

use strict;
use warnings;
use JSON::XS;
use Padre::Wx      ();
use Padre::Service ();
use Padre::Swarm::Message;
use IO::Select;
use IO::Socket::Multicast;

our $VERSION = '0.08';
our @ISA     = 'Padre::Service';

use Class::XSAccessor
	accessors => {
		task_event => 'task_event',
		service    => 'service',
		client     => 'client',
	};

=pod

=head1 Padre::Service::Swarm - Buzzing Swarm!

Join the buzz , schedule a Swarm service to throw a event at you 
when something interesting happens.

=head1 SYNOPSIS

=head1 METHODS

=cut

use Carp qw( cluck  croak);
use Data::Dumper;

sub hangup {
	my $self = shift;
	my $running = shift;
	$$running = 0;
	$self->client->shutdown(1);
	$self->client(undef);
	
}

sub terminate {
	my $self = shift;
	my $running = shift;
	$$running=0;
	$self->client(undef);

}

SCOPE: {
	my $service;
	sub service_loop {
		my $self = shift;
		
		if (my ($message) = $self->poll(0.2) ) {
			$self->handle_message($message);
		}
		
		return 1;
	}
}

sub poll  {
	my $self = shift;
	my $timeout = shift || 0.5;
	my $poll = IO::Select->new;
	$poll->add( $self->{client} );
	my ($ready) = $poll->can_read($timeout);
	if ($ready) {
		my ($message) = $self->receive($ready);
		if ($message) {
			return $message;
1		}
	}
	
}

sub receive {
	my $self = shift;
	my $sock = shift;
	my $buffer;
	my $remote = $sock->recv( $buffer, 65535 );
	if  ( $remote ) {
		my ($rport,$raddr) = sockaddr_in $remote;
		my $ip = inet_ntoa $raddr;
		my $message = eval { $self->marshal->decode( $buffer ) };
		# todo - include the transport info in the message
		if ( $@ ) {
			warn "Swarm Failed decoding ! $@ --- '$buffer'";
		}
		return $message;;
	}
	
}

sub start {
	my $self = shift;
	
	my $client = IO::Socket::Multicast->new(
		LocalPort => 12000,
		ReuseAddr => 1,
	) or die $!;
	$client->mcast_add('239.255.255.1'); #should have the interface
	$client->mcast_loopback( 1 );
	
	$self->{client} = $client;
	$self->{running} = 1;


}

sub handle_message {
	my $self = shift;
	my $message = shift;
	return unless $message;
	$message->{transport} = 'local';
	$self->post_event( 
		$self->event, 
		Storable::freeze ($message)
	);
}

sub marshal {
	JSON::XS->new
		->allow_blessed
		->convert_blessed
		->utf8
		->filter_json_object(\&synthetic_class );
}

sub synthetic_class {
	my $var = shift ;
	if ( exists $var->{__origin_class} ) {
		my $stub = $var->{__origin_class};
		my $msg_class = 'Padre::Swarm::Message::' . $stub;
		my $instance = bless $var , $msg_class;
		return $instance;
	} else {
		return bless $var , 'Padre::Swarm::Message';
	}
};


1;

# Copyright 2008-2010 The Padre development team as listed in Padre.pm.
# LICENSE
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl 5 itself.
