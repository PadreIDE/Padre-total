package Padre::Plugin::Swarm::Transport::Local::Multicast;
use strict;
use warnings;
use Wx qw( :socket );
use Padre::Wx ();
use Padre::Logger;
use base qw( Padre::Plugin::Swarm::Transport );


our $VERSION = '0.08';

use Class::XSAccessor
    constructor => 'new',
    accessors => {
        socket => 'socket',
        service => 'service',
        config => 'config',
        on_connect => 'on_connect',
        on_disconnect => 'on_disconnect',
        on_recv => 'on_recv',
        marshal => 'marshal',
    };
    


sub connect { 
    my $self = shift;
    # build the transmitting socket
    my $mcast_address = Wx::IPV4address->new;
    $mcast_address->SetHostname('239.255.255.1');
    $mcast_address->SetService(12000);

    # Local address 
    my $local_address = Wx::IPV4address->new;
    $local_address->SetAnyAddress;
    $local_address->SetService( 0 ); # 0 == random source port
    my $transmitter = Wx::DatagramSocket->new( $local_address );

    $self->socket( $transmitter );

    # start the service thread listener
    my $service = Padre::Plugin::Swarm::Transport::Multicast::Service->new;
    $self->service($service);
    $service->schedule;
    Wx::Event::EVT_COMMAND(
		$self->plugin->wx,
		-1,
		$service->event,
		sub { $self->on_service_recv(@_) }
	);
}

sub disconnect {
    my $self = shift;
    $self->socket->Destroy;
    $self->service->hangup;
    
    # teardown the transmitting socket
    # hangup the service thread
    
}

sub on_service_recv {
    my ($self,$wx,$evt) = @_;
    my $data = $evt->GetData;
    ## TODO - fix Padre::Service to have an event for started/stopped
    if ( $data eq 'ALIVE' ) {
        $self->on_connect->() if $self->on_connect;
        return;
    }
    
    my @messages = eval { $self->marshal->decode($data) };
    if ( $@ ) {
        TRACE( "Failed to decode data '$data' , $@" ) if DEBUG;
    }
    if ( $self->on_recv ) {
        $self->on_recv( $_ ) for @messages;
    }
}

# Send a Padre::Swarm::Message
sub send {
    my $self = shift;
    my $message = shift;
    my $data = eval { $self->marshal->encode( $message ) };
    if ($@) { 
        TRACE( "Failed to encode $message - $@" ) if DEBUG;
        return;
    }
    
    $self->write($data);
    
}

# Write encoded data to socket
sub write {
    my $self = shift;
    my $data = shift;
    $self->socket->SendTo( $self->mcast_address, $data, length($data) );
    
}

1;
