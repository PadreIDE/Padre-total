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
   };
   
use Carp;

our @ISA = 'Padre::Swarm::Transport';



sub start {
	my $self = shift;
	
	my $con = AnyEvent::IRC::Client->new;
	$con->connect (
		"irc.perl.org" => 6667 ,
		{ nick => 'swarm_submersible' ,
		  user => 'Padre-Swarm-Transport-IRC' ,
		  real => getlogin() 
		}
	);
	
	$self->{connection} = $con;
	$self->_register_irc_callbacks($con);
	my $c = AnyEvent->condvar;
	$self->{condvar} = $c;
	
	

}

sub shutdown {
	my $self = shift;
	$self->connection->disconnect;
	delete $self->{connection};
}

sub _register_irc_callbacks {
	my ($self,$con) = @_;
warn "REGISTER CALLBACKS";

	$con->reg_cb (
	   connect => sub {
	      my ($con, $err) = @_;
	      if (defined $err) {
		 warn "Connect ERROR! => $err\n";
		 $self->condvar->broadcast;
	      } else {
		 Padre::Util::debug( "Connected! Yay!\n" );
	      }

		$con->send_srv( JOIN => '#padre' );
#		$con->register( 
#		  $self->nickname,
#		  'Padre-Swarm-Transport-IRC',
#		  , getlogin() 
#		);
		
	   },
	   disconnect => sub {
	      warn "Oh, got a disconnect: $_[1], exiting...\n";
	      $self->condvar->broadcast;
	   }
	);

	$con->reg_cb(
	   publicmsg => sub {
	      my ($handle,$channel,$ircmsg)= @_;
	      my $nick = $con->nick;
	      
	      my $body = join (' ',@{ $ircmsg->{params} } );
	      my $msg = { 
		    user => $ircmsg->{prefix}, 
		    message => $body , 
		    type => 'chat',
	       };
	       my $frame = {
		       address => $handle,
		       channel => $channel,
	       };
	       warn "Publick message in $channel from $handle";
	       push @{ $self->{incoming_buffer}{$channel} }, [$msg,$frame];
		    
	   }
	);


}


sub _connect_channel {
	my ($self,$channel) = @_;
	my $con = $self->connection;
	my $room = '#padre_swarm_' . $channel;
	warn "Join #padre";
	$con->send_srv( JOIN => '#padre' );
}



sub poll {
	my ($self,$time) = @_;
#	warn "Polling for $time:";
	my $c = AnyEvent->condvar;
	my $timer = AnyEvent->timer( after=>$time,
		cb=>sub{ $c->send } );
	$c->recv;
#	warn "Returned from poll wait";
	if ( keys %{ $self->{incoming_buffer} } ) {
		warn "DATA IN BUFFER!";
		return keys %{ $self->{incoming_buffer} };
	}

}

sub receive_from_channel {
	my ($self,$channel) = @_;
	return unless exists $self->{incoming_buffer}{$channel};
	shift @{ $self->{incoming_buffer}{$channel} };
	
}

sub tell_channel {
	my ($self,$channel,$payload) = @_;
	my $con = $self->connection;
	
	$con->send_chan( '#padre', 'PRIVMSG',
		'#padre',
		$payload
	);
}
1;
