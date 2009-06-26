package Padre::Swarm::Service::Chat;

use strict;
use warnings;
use JSON::XS    ();
use Padre::Swarm::Transport::Multicast ();
use Class::XSAccessor
    getters => {
        get_transport => 'transport',
    },
    setters => {
        set_transport => 'transport',
    };

sub service_channels { 12000 };

sub service_name { 'chat' };

sub start { 
    my $self = shift;
    
    my $mc = Padre::Swarm::Transport::Multicast->new();
    $mc->subscribe_channel( $_)
        for $self->service_channels;
    $mc->start; 
    $self->set_transport( $mc ); 
    $self->send( { user => getlogin , announce=>1 } );
    
}

sub shutdown {
        my $self = shift;
        $self->send( { user => getlogin , goodbye=>1 } );
        $self->get_transport->shutdown;
}

sub new {
    my ($class,$config) = @_;

    
    my $self = bless {} , $class;
    return $self;
}

sub chat {
    my ($self,$text) = @_;
    $self->send(
        { user => getlogin, says=>$text }
    );
}

sub say_to {
    my ($self,$text,$entity) = @_;
    $self->send( 
        { user => getlogin, says=>$text, to=>$entity }
    );
}

sub send {
    my ($self,$message) = @_;
    my $payload = JSON::XS::encode_json( $message );
    $self->get_transport->tell_channel( 
        12000 => $payload,
    );
    
}

1;