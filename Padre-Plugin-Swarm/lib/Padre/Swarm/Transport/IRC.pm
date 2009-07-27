package Padre::Swarm::Transport::IRC;

use strict;
use warnings;
use Carp qw( carp confess );
use Padre::Swarm::Transport;
require Padre::Swarm::Identity; # thread quackery?
use AnyEvent;
use AnyEvent::IRC::Client;

our $VERSION = '0.01';
our @ISA     = 'Padre::Swarm::Transport';

use Class::XSAccessor
	getters => {
		connection => 'connection',
		condvar    => 'condvar',
		enable_ssl => 'enable_ssl',
	};

sub start {
	my $self = shift;
	my $con = AnyEvent::IRC::Client->new;
	$con->enable_ssl if $self->enable_ssl;

	$con->connect(
		"irc.perl.org" => 6667,
		{
			nick => $self->identity->nickname,
			user => $self->identity->resource,
			real => getlogin(),
		}
	);

	$self->_register_irc_callbacks($con);
	$self->{connection} = $con;

	my $c = AnyEvent->condvar;
	$self->{condvar} = $c;
	$self->{started} = 1;
}

sub shutdown {
	my $self = shift;
	$self->shutdown_channels;
	$self->connection->disconnect;
	delete $self->{connection};
	delete $self->{condvar};
	$self->{started} = 0;
	
	1;
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
	      warn "Oh, got a disconnect: $_[0], exiting...\n";
	      $self->condvar->broadcast;
	   },
	   registered => sub {
		$self->update_channels;
	   }
	);

	$con->reg_cb(
	   publicmsg => sub { $self->buffer_incoming(@_) },
	   privatemsg   => sub { $self->buffer_incoming_private(@_) },
	  
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

sub _shutdown_channel {
	my ($self,$channel) = @_;
	return 1 unless $self->{started};
	my $con = $self->connection;
	confess 'no connection' unless $con;
	
	my $room = '#padre_swarm_' . $channel;
	$con->send_srv( PART => $room );
	
}

sub update_channels {
	my ($self) = @_;
	while ( my ($channel,$loopback) = each %{ $self->subscriptions } ) {
		$self->_connect_channel( $channel, $loopback );
	}
	
}

sub shutdown_channels {
	my ($self) = @_;
	while ( my ($channel,$loopback) = each %{ $self->subscriptions } ) {
		$self->_shutdown_channel( $channel, $loopback );
	}
}

sub poll {
	my ($self,$time) = @_;
	#warn "Polling for $time:";
	my $c = AnyEvent->condvar;
	my $timer = AnyEvent->timer( after=>$time,
		cb=>sub{ $c->send } );
	#warn "$timer running";
	
	if ( keys %{ $self->{outgoing_buffer} } ) {
		while ( my ($channel,$buffer) = each %{ $self->{outgoing_buffer} } ){
			next unless @$buffer;
			my $irc_chan = '#padre_swarm_'.$channel;
			#warn "Sending channel $irc_chan data x " . scalar @$buffer, $/;
			#warn Dumper $buffer;
			while ( my $msg = shift @$buffer ) {
				#warn "Sending to '$irc_chan' , $msg ";
				$self->connection->send_chan( $irc_chan,
					'PRIVMSG'=>$irc_chan ,
					$msg 
				) 
			}
		}
	
	}
	
	$c->recv;
	#warn "Returned from poll wait";
	if ( keys %{ $self->{incoming_buffer} } ) {
		#warn "DATA IN BUFFER!", Dumper $self->{incoming_buffer} ;
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
	#else { warn "Drained '$channel' buffer" }
	
	return @$d;
}

sub tell_channel {
	my ($self,$channel,$payload) = @_;
	$self->push_write( $channel, $payload );
	if ( $self->loopback ) {
		push @{ $self->{incoming_buffer}{$channel} }, [$payload,{transport=>'loopback',channel=>$channel}];
	}
}

sub buffer_incoming_private {
	my ($self,$con,$command,$ircmsg) = @_;
	#warn "Got incoming $command with " ,Dumper $ircmsg;
}

sub buffer_incoming {
	my ($self,$handle,$channel,$ircmsg)= @_;
	my $con = $self->connection;
	my $nick = $con->nick;
	my ($sender,$body) = @{ $ircmsg->{params} };
	warn "Buffering from $sender --- $body";

	my $frame = {
		identity  => $sender,
		transport => 'irc',
		channel   => $channel,
		timestamp => time, 
	};
	push @{ $self->{incoming_buffer}{$channel} }, [ $body, $frame ];
}

1;
