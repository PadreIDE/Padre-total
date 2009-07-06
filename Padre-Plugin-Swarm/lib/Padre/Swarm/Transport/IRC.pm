package Padre::Swarm::Transport::IRC;

use strict;
use warnings;
use Padre::Swarm::Transport;

use AnyEvent;
use AnyEvent::IRC::Client;
use Class::XSAccessor
   getters => {
	   connection => 'connection',
	   condvar	=> 'condvar',
	   nickname    => 'nickname',
	   
	   enable_ssl  => 'enable_ssl',
   };
   
use Carp qw( carp );

our @ISA = 'Padre::Swarm::Transport';
use Data::Dumper;


sub start {
	my $self = shift;
	
	my $con = AnyEvent::IRC::Client->new;
	$con->enable_ssl if $self->enable_ssl;

	$con->connect (
		"irc.perl.org" => 6667 ,
		{ nick =>  $self->nickname,
		  user => 'Padre-Swarm-Transport-IRC' ,
		  real => getlogin() 
		}
	);
	$self->_register_irc_callbacks($con);
	$self->{connection} = $con;

	my $c = AnyEvent->condvar;
	$self->{condvar} = $c;
	
	

}

sub shutdown {
	my $self = shift;
	$self->connection->disconnect;
	delete $self->{connection};
	delete $self->{condvar};
}

sub _register_irc_callbacks {
	my ($self,$con) = @_;
	$con->reg_cb (
	   connect => sub {
	      my ($con, $err) = @_;
	      if (defined $err) {
		 Padre::Util::debug("Connect ERROR! => $err\n");
		 $self->condvar->broadcast;
	      } else {
		 Padre::Util::debug( "Connected! Yay!\n" );
	      }

#		$con->register( 
#		  $self->nickname,
#		  'Padre-Swarm-Transport-IRC',
#		  , getlogin() 
#		);
		
	   },
	   disconnect => sub {
	      warn "Oh, got a disconnect: $_[1], exiting...\n";
	      $self->condvar->broadcast;
	   },
	   registered => sub {
		$self->update_channels;
	   }
	);

	$con->reg_cb(
	   publicmsg => sub {
	      my ($handle,$channel,$ircmsg)= @_;
	      my $nick = $con->nick;
	      
	      my ($sender,$body) =  @{ $ircmsg->{params} };
	      
	       my $frame = {
		       entity => $sender,
		       channel => $channel,
		       timestamp => time, 
	       };
	       push @{ $self->{incoming_buffer}{$channel} }, [$body,$frame];
		    
	   }
	);
	
	$con->reg_cb(
		error => sub {
			my ($con,$code, $message, $ircmsg) = @_;
			warn "ERROR:[$code] - $message\n";
			
		}

	);


}


sub _connect_channel {
	my ($self,$channel) = @_;
	my $con = $self->connection;
	my $room = '#padre_swarm_' . $channel;
	$con->send_srv( JOIN => $room );
}


use Data::Dumper;
sub update_channels {
	my ($self) = @_;
	while ( my ($channel,$loopback) = each %{ $self->subscriptions } ) {
		$self->_connect_channel( $channel, $loopback );
	}
	
}


sub poll {
	my ($self,$time) = @_;
	#warn "Polling for $time:";
	my $c = AnyEvent->condvar;
	my $timer = AnyEvent->timer( after=>$time,
		cb=>sub{ $c->send } );
	#warn "$timer running";
	$c->recv;
	#warn "Returned from poll wait";
	if ( keys %{ $self->{incoming_buffer} } ) {
		warn "DATA IN BUFFER!", %{ $self->{incoming_buffer} };
		return (keys %{ $self->{incoming_buffer} });
	}
	return;

}


sub receive_from_channel {
	my ($self,$channel) = @_;
	return unless exists $self->{incoming_buffer}{$channel};
	
	my @queue = @{ delete $self->{incoming_buffer}{$channel} };
	my $d = shift @queue;
	if ( @queue ) {
		$self->{incoming_buffer}{$channel} = \@queue
	}
	else { warn "Drained '$channel' buffer" }
	
	return @$d;
}

sub tell_channel {
	my ($self,$channel,$payload) = @_;
	my $con = $self->connection;
	carp "Tell $channel - $payload";
	my $irc_chan = '#padre_swarm_'.$channel;
	
	$con->send_msg( PRIVMSG => $irc_chan,
		$payload
	);
	
	#$con->send_chan($irc_chan, $payload );
}
1;
