package Padre::Swarm::Transport::XMPP;

use strict;
use warnings;
use Padre::Swarm::Transport;

use AnyEvent;
use AnyEvent::XMPP::Client;
use AnyEvent::XMPP::Ext::Disco;
use AnyEvent::XMPP::Ext::MUC;
use Class::XSAccessor
   getters => {
	   connection => 'connection',
	   condvar	=> 'condvar',
	   nickname    => 'nickname',
	   credentials => 'credentials',
   };
   
use Carp qw( carp );

our @ISA = 'Padre::Swarm::Transport';

sub start {
	my $self = shift;
		
	my $con = AnyEvent::XMPP::Client->new(
		debug => 1,
	);
	$con->add_account( $self->credentials->{username},
			$self->credentials->{password},			
	);
	$con->add_extension (my $disco = AnyEvent::XMPP::Ext::Disco->new);
	$con->add_extension (my $muc = AnyEvent::XMPP::Ext::MUC->new (disco => $disco));
	
	
	$con->start;
	$self->_register_xmpp_callbacks($con);
	$self->{connection} = $con;

	my $c = AnyEvent->condvar;
	$self->{condvar} = $c;
	
	
	
}

sub _register_xmpp_callbacks {}


sub shutdown {
	my $self = shift;
	$self->connection->disconnect;
	
}

sub tell_channel {}

sub receive_from_channel {}

1;
