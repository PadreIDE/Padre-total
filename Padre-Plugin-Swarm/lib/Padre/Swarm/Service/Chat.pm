package Padre::Swarm::Service::Chat;

use strict;
use warnings;

use Carp qw( croak confess carp );
use Params::Util qw( _INSTANCE _CLASSISA _INVOCANT);
use Data::Dumper ();

require JSON::XS;
use Time::HiRes ();

use Padre::Debug;
use Padre::Plugin::Swarm ();
use Padre::Swarm::Service ();
use Padre::Swarm::Message ();
use Padre::Swarm::Transport::Multicast ();
use Padre::Util;
our $VERSION = '0.05';
our @ISA     = 'Padre::Swarm::Service';


use Class::XSAccessor
	getters => {
		transport => 'transport',
	},
	setters => {
		set_transport => 'transport',
	};

#use constant DEBUG => Padre::Plugin::Swarm::DEBUG;

sub marshal {
	JSON::XS->new
		->allow_blessed
		->convert_blessed
		->utf8
		->filter_json_object(\&synthetic_class );
}

sub service_channels { 12000 };

sub service_name { 'chat' };

sub start { 
	my $self = shift;
	TRACE('Starting chat service') if DEBUG;
	my $config = Padre::Config->read;

	$self->_attach_transports;
	TRACE('Chat transports attached') if DEBUG;
	TRACE( $self->transport ) if DEBUG;

	TRACE('Channels subscribed') if DEBUG;
	$self->transport->start; 
	#Time::HiRes::sleep(0.5); # QUACKERY.. socket construction?
	$self->queue->enqueue(
		Padre::Swarm::Message->new(
			type => 'disco',
			want => [ 'chat' ],
		)
	);

	$self->queue->enqueue(
		Padre::Swarm::Message->new(
			type => 'announce',
			from => $self->identity->nickname,
		) 
	);
}

sub service_loop {
	my ($self,$message) = @_;
	TRACE("Service [$self] loop!\n") if DEBUG;
	my $queue = $self->queue;
	#TRACE("\t$queue " . $queue->pending , $/) if DEBUG;
	if ( _INSTANCE( $message, 'Padre::Swarm::Message' ) ){
		TRACE("Chat send $message") if DEBUG;
		$self->send( $message );
	} elsif( _INSTANCE( $message, 'Padre::Swarm::Message::Diff' ) ) {
		$self->send( $message );
	}

	if ( my @ready =  $self->transport->poll(0.5) ) {
		TRACE("Transport has ready = " . @ready ) if DEBUG;
		my @messages;
		foreach ( @ready ) {
			push @messages, $self->transport->receive_from_channel($_);
		}
		while ( my ($payload,$frame) = splice(@messages,0,2) ) {
			warn(
				'Decoding ' .
				Data::Dumper->Dump( [ $payload ] )
			) if DEBUG;
			my $message = eval {
				$self->marshal->decode( $payload );
			};
			unless ( $message ) {
				TRACE("Decode failed for $payload \n\t - with $@") if DEBUG;
				next;
			}

			$message->{$_} = $frame->{$_}
				for keys %$frame;

			eval { $self->receive( $message ) };
			if ( $@ ) {
				TRACE("FAILED receive $@") if DEBUG;
			}
		}
	}
}

sub shutdown {
        my $self = shift;
        TRACE( 'Requested shutdown of service' ) if DEBUG;
        return unless $self->running;
        $self->send( 
          Padre::Swarm::Message->new(
            type => 'leave', 
          )
        );
        
        return unless $self->running;
        $self->transport->shutdown;
}

use Carp qw( cluck );
sub hangup {
	my ($self,$running) = @_;
	$self->shutdown;
	$$running = 0;
}

sub terminate {
	my ($self,$running) = @_;
	$self->shutdown;
	$$running = 0;
}

sub new {
	my ($class,%config) = @_;
	my $self = bless {%config} , $class;
	return $self;
}


sub chat {
	my ($self,$text) = @_;
	$self->send(
		Padre::Swarm::Message->new(
			body => $text,
		)
	);
}

sub say_to {
	my ($self,$text,$entity) = @_;
	my $msg = Padre::Swarm::Message->new(
		body => $text,
		to   => $entity,
	);
	$self->send( $msg );
}

sub send {
	my ($self, $message) = @_;

	if ( _INSTANCE($message, 'Padre::Swarm::Message') ) {
		TRACE(Dumper $message) if DEBUG;
		unless ( $message->from ) {
			my $nickname = $self->identity->nickname;
			$message->from( $self->identity->nickname );
		}
		unless ( $message->type ) {
			$message->type('chat');
		}
	}

	my $payload = $self->marshal->encode( $message );
	$self->transport->tell_channel( 
		12000 => $payload,
	);
}

sub promote {
	my ($self, $message) = @_;
	my $service_name = $self->service_name;
	# if $message->wants( $service_name ); when message is object!pls!
	$self->send(
		Padre::Swarm::Message->new(
			type    => 'promote',
			service => "$self",
		)
	);
}

sub receive {
	my $self    = shift;
	my $message = shift;
	unless ( _INSTANCE($message, 'Padre::Swarm::Message') ) {
		confess "Did not receive a message!";
	}

	my $type = $message->type;
	$type ||= '';
    
	if ( $type eq 'disco' ) {
		$self->promote($message);
	}

	# cheap taudry hack
	my $body = $message->body;
	if ( defined $body && $body =~ m|/disco| ) {
		$self->promote($message);
	}
    
	$self->post_event( $self->event , Storable::freeze($message) );
	return;
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
