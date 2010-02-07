package Padre::Plugin::Swarm::Transport::Global::WxSocket;
use strict;
use warnings;
use JSON::XS;
use Wx qw( :socket );
use Padre::Wx ();
use Padre::Logger;

our $VERSION = '0.08';

use Class::XSAccessor
    constructor => 'new',
    accessors => {
        socket => 'socket',
        config => 'config',
        on_connect => 'on_connect',
        on_disconnect => 'on_disconnect',
        on_recv => 'on_recv',
        marshal => 'marshal',
    };
    

sub plugin { Padre::Plugin::Swarm->instance }

sub enable {
    my $self = shift;
    
    my $marshal = JSON::XS->new;
    $self->{marshal} = $marshal;
#    my $config = $self->plugin->config_read;
#    my $servername = $config->{global_server};
    my $servername = 'swarm.perlide.org';

    $self->connect( $servername ) ;
}

sub disable { 
    my $self = shift;
    $self->socket->Destroy;
    
}

sub connect {
    my $self = shift;
    my $addr = shift;
    my $wx = $self->plugin->wx;
    
    my $sock = Wx::SocketClient->new(
        Wx::wxSOCKET_NOWAIT
    ) ;
    
    $self->{socket} = $sock;
    
    Wx::Event::EVT_SOCKET_CONNECTION( $wx, $sock,
        sub { $self->on_socket_connect(@_) },
    );

    Wx::Event::EVT_SOCKET_LOST($wx , $sock , 
        sub { $self->on_socket_lost(@_) }
    ) ;
    


    #                         Don't wait for it!
    $sock->Connect( $addr , 12000, 0 );
    
    

}

sub disconnect {
    my $self = shift;
    warn "Disconnect!";
    $self->socket->Destroy;
    
}


sub on_socket_connect {
    my ($self,$sock,$wx,$evt) = @_;
    
   # my $data = $evt->GetClientData; # UNsupported ?
   TRACE( "Connected!" ) if DEBUG;
   # Send a primative session start
    my $payload =  $self->marshal->encode(
            { type=>'session' , trustme=>'foo' }
        );

    $sock->Write( $payload , length($payload) );
    
    Wx::Event::EVT_SOCKET_INPUT($wx, $sock ,
        sub { $self->on_session_start(@_ ) }
    ) ;
    

   # TODO set a timer to wait for the session response

}
use Data::Dumper;

sub on_session_start {
    my ($self,$sock,$wx,$evt) = @_;
    my $data = '';
    my $message;
    my $marshal = $self->marshal;
    while ( $sock->Read( $data , 1024,  length($data) ) ) {
        $message = eval { $marshal->incr_parse($data) }; 
        if ( $@ ) { $marshal->incr_skip }
        last if $message;
        $data='';
    }

    if ( $message->{session} eq 'authorized' ) {
        $self->{token} = $message->{token};
        TRACE( "Authorized with " . $message->{token} ) if DEBUG;
       
        Wx::Event::EVT_SOCKET_INPUT($wx, $sock ,
            sub { $self->on_socket_input(@_ ) }
        ) ;
        
        # Send any buffered messages
        if ($self->{write_queue}) {
            $self->write( $_ ) for @{ $self->{write_queue} }
        }
        
        $self->on_connect->() if $self->on_connect;
        
    }
    
}


sub on_socket_lost {
    my ($self,$sock,$wx,$evt) = @_;
    TRACE( "Socket lost" ) if DEBUG;
    $self->on_disconnect->($evt)
        if $self->on_disconnect;

}

sub on_socket_input {
    my ($self,$sock,$wx,$evt) = @_;
    $evt->Skip(0) unless $self->{token};
    
    TRACE( "Socket Input" ) if DEBUG;
    my $marshal = $self->marshal;
    
    my @messages;
    my $data = '';
    # TODO - can we yield to WxIdle in here? .. safely?
    while ( $sock->Read( $data, 1024 ) ) {
        my $m = eval { $marshal->incr_parse($data) };
        if ($@) {
            TRACE( "Unparsable message - $@" ) if DEBUG;
            $data = '';
            $marshal->incr_skip;
        } else {
            push @messages ,$m if $m;
        }
        $data='';
    }
    
    foreach my $m ( @messages ) {
        next unless ref $m eq 'HASH';
        my $type = $m->{type};
        my $origin = $m->{__origin_class};
        my $class = $origin || 'Padre::Swarm::Message::'.ucfirst($type);
        bless $m , $class;
        $self->on_recv->($m) if $self->on_recv;
    }
    
}

sub write {
    my $self = shift;
    my $data = shift;
    # Only write if the session has started
    if ( $self->{token} ) {
        $self->socket->Write( $data, length($data) );
    }
    else {
        push @{ $self->{write_queue} }, $data;
    }
    
}

sub DESTROY { warn "DESTROYED " , shift };

1;
