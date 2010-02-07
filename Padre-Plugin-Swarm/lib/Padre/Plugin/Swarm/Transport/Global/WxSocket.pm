package Padre::Plugin::Swarm::Transport::Global::WxSocket;
use strict;
use warnings;
use JSON::XS;
use Wx qw( :socket );
use Padre::Wx ();

our $VERSION = '0.08';

use Class::XSAccessor
    constructor => 'new',
    accessors => {
        socket => 'socket',
        config => 'config',
        on_connect => 'on_connect',
        on_disconnect => 'on_disconnect',
        on_recv => 'on_recv',
    };
    

sub plugin { Padre::Plugin::Swarm->instance }

sub enable {
    my $self = shift;
#    my $config = $self->plugin->config_read;
#    my $servername = $config->{global_server};
    my $servername = 'localhost';
    my $addr = Wx::IPV4address->new();
    $self->connect( $addr ) ;
}

sub connect {
    my $self = shift;
    my $addr = shift;
    my $wx = $self->plugin->wx;
    
    my $sock = Wx::SocketClient->new(
        Wx::wxSOCKET_WAITALL
    ) ;
    
    $self->{socket} = $sock;
    
    Wx::Event::EVT_SOCKET_CONNECTION( $wx, $sock,
        sub { $self->on_socket_connect(@_) },
    );

    Wx::Event::EVT_SOCKET_LOST($wx , $sock , 
        sub { $self->on_socket_lost(@_) }
    ) ;
    


    #                         Don't wait for it!
    $sock->Connect( 'localhost' , 12000, 0 );
    
    

}

sub disconnect {
    my $self = shift;
    warn "Disconnect!";
    $self->socket->Destroy;
    
}


sub on_socket_connect {
    my ($self,$sock,$wx,$evt) = @_;
    warn "Socket connected state = " , @_;
    
    warn $sock->IsConnected;
   # my $data = $evt->GetClientData; # UNsupported ?
   
   # Send a primative session start
    my $payload =  JSON::XS::encode_json(
            { type=>'session' , trustme=>'foo' }
        );

    $sock->Write( $payload , length($payload) );
    Wx::Event::EVT_SOCKET_INPUT($wx, $sock ,
        sub { $self->on_session_start(@_ ) }
    ) ;
    
    Wx::Event::EVT_SOCKET_INPUT($wx, $sock ,
        sub { $self->on_socket_input(@_ ) }
    ) ;
   # TODO set a timer to wait for the session response

}

sub on_session_start {
    my ($self,$sock,$wx,$evt) = @_;
    warn "SESSION START!";
    my $data = ' ';
    while ( $sock->Read( $data , 1,  length($data) ) ) {
        last if $data =~ /\n$/s;
    }
    my $message = eval { JSON::XS::decode_json( $data ); };
    warn "Got message $message" if $message;
    warn "Failed to decode message '$data' - $@" if $@;
    if ( $message->{session} eq 'authorized' ) {
        $self->{token} = $message->{token};
    }
    
}


sub on_socket_lost { warn "SOCKET LOST" }

sub on_socket_input { warn "SOCKET INPUT " , @_ }

sub DESTROY { warn "DESTROYED " , shift };

1;
