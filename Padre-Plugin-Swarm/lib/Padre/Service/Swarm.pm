package Padre::Service::Swarm;

use strict;
use warnings;
use Padre::Wx      ();
use Padre::Service ();
use Padre::Swarm::Message;
use IO::Select;
use IO::Interface;
use IO::Interface::Simple;
use IO::Socket::Multicast;
use Padre::Logger;


our $VERSION = '0.06';
our @ISA     = 'Padre::Service';

use Class::XSAccessor
	accessors => {
		task_event => 'task_event',
		service    => 'service',
		client     => 'client',
		sender     => 'sender',
		interface  => 'interface',
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
	$self->interface(undef);
	$self->sender->shutdown(1);
	$self->sender(undef);
	
	
}

sub terminate {
	my $self = shift;
	my $running = shift;
	$$running=0;
	$self->client(undef);
	$self->interface(undef);
	$self->sended(undef);
	

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
	$self->find_multicast_interface;
	
	my $sender = IO::Socket::Multicast->new();
	$self->{sender} = $sender;
	
	my $client = IO::Socket::Multicast->new(
		LocalPort => 12000,
		ReuseAddr => 1,
		#PeerAddr=>$self->interface->address,
		#Proto=>'udp',
	) or die $!;
	$client->mcast_add('239.255.255.1', $self->interface );
	$client->mcast_loopback( 1 );
	
	$self->{client} = $client;
	$self->{running} = 1;


}

sub find_multicast_interface {
	my $self = shift;
    my $interface;
    foreach my $i ( IO::Interface::Simple->interfaces ) {
        next unless $i->is_multicast
            && $i->is_running
            && $i->address;
        $interface = $i;
    } continue { last if $interface }
    die "No usable multicast interface" unless $interface;
   $self->interface($interface);
}

sub send_message {
	my $self = shift;
	my $message = shift;
	my $data = $self->marshal->encode($message);
	return unless $self->{sender};
	$self->{sender}->mcast_send($data,'239.255.255.1:12000' );
	
	
}

sub handle_message {
	my $self = shift;
	my $message = shift;
	return unless $message;
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
