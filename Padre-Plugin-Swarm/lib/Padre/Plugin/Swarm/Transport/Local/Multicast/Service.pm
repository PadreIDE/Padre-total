package Padre::Plugin::Swarm::Transport::Local::Multicast::Service;
use strict;
use warnings;
use JSON;
use Padre::Wx      ();
use Padre::Service ();
use Padre::Logger;
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


sub hangup {
	my $self = shift;
	my $running = shift;
	$$running = 0;
	$self->client->shutdown(1) if $self->client;
	$self->client(undef);
	
}

sub terminate {
	my $self = shift;
	my $running = shift;
	$$running=0;
	$self->client(undef);

}


sub service_loop {
	my $self = shift;
	
	if (my ($message) = $self->poll(0.2) ) {
		$self->post_event( 
			$self->event, 
			$message
		);
	}
	
	return 1;
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
		}
	}
	return ();
}

sub receive {
	my $self = shift;
	my $sock = shift;
	my $buffer;
	my $remote = $sock->recv( $buffer, 65535 );
	if  ( $remote ) {
		#my $marshal = Padre::Plugin::Swarm::Transport->_marshal;
		#my ($rport,$raddr) = sockaddr_in $remote;
		#my $ip = inet_ntoa $raddr;
		return $buffer;
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
	$self->post_event(
		$self->event,
		'ALIVE'
	);

}



1;

# Copyright 2008-2010 The Padre development team as listed in Padre.pm.
# LICENSE
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl 5 itself.
