package Padre::Swarm::Service::Chat;

use strict;
use warnings;
use JSON::XS;
use Time::HiRes ();
use Padre::Swarm::Transport::Multicast ();
use Padre::Swarm::Service ();

my $marshal = JSON::XS->new->allow_blessed->convert_blessed;
    
our @ISA = 'Padre::Swarm::Service';

use Class::XSAccessor
    getters => {
        transport => 'transport',
    },
    setters => {
        set_transport => 'transport',
    };

sub service_channels { 12000 };

sub service_name { 'chat' };

sub start { 
    my $self = shift;
    Padre::Util::debug('Starting chat service');
    my $config = Padre::Config->read;
    $self->_attach_transports;
    Padre::Util::debug('Chat transports attached');  
    Padre::Util::debug( $self->transport );
    
    $self->transport->subscribe_channel( $_ )
        for $self->service_channels;
    
    Padre::Util::debug('Channels subscribed');
    $self->transport->start; 
    Time::HiRes::sleep(0.5); # QUACKERY.. socket construction?
    $self->queue->enqueue( { type=>'disco' , want=>['chat'] } );
    
    $self->queue->enqueue( { type=>'announce',  } );
    
}

sub service_loop {
    my ($self,$message) = @_;
    Padre::Util::debug("Service [$self] loop!\n") ;
    my $queue = $self->queue;
    #Padre::Util::debug("\t$queue " . $queue->pending , $/);
    $self->send( $message ) if $message;
    
    
    if ( my @ready =  $self->transport->poll(0.5) ) {
        Padre::Util::debug("Transport has ready = " . @ready );
        my @messages;
        push @messages,
            $self->transport->receive_from_channel($_)
                for @ready;
        while ( my ($payload,$frame) = splice(@messages,0,2) ) {
            my $message = eval { $marshal->decode( $payload ); };
            unless ($message) {
                $self->task_warn($@ );
                $self->task_warn($message);
                next;
            }
            
            $message->{$_} = $frame->{$_}
                for keys %$frame;
                
            $self->receive( $message );
        }
    }
}

sub shutdown {
        my $self = shift;
        Padre::Util::debug( 'Requested shutdown of service' );
        return unless $self->running;
        $self->transport->shutdown;
}

sub hangup {
    my ($self,$running) = @_;
    $self->transport->shutdown;
    $$running = 0;
}

sub terminate {
    my ($self,$running) = @_;
    $self->transport->shutdown;
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
        {message=>$text }
    );
}

sub say_to {
    my ($self,$text,$entity) = @_;
    $self->send( 
        { message=>$text, to=>$entity }
    );
}

sub send {
    my ($self,$message) = @_;
    unless ( $self->running ) {
        $self->task_warn( "Send ignored. Service not running" );
        return;
    }
    my $payload = $marshal->encode( $message );
    $self->transport->tell_channel( 
        12000 => $payload,
    );
    
}
sub promote {
    my ($self,$message) = @_;
    
    my $service_name = $self->service_name;
    # if $message->wants( $service_name ) ; when message is object!pls!
    $self->send({type=>'promote', service=>$self});

    
}

use Data::Dumper;
sub receive {
    my $self = shift;
    my $message = shift;
    my $type = $message->{type};
    $type ||= '';
    
    if ( $type eq 'disco' ) {
        $self->promote($message);
    }

# cheap taudry hack
    my $body = $message->{message};
    if ( defined $body && $body =~ m|^/disco| ) {
        $self->promote({});
    }
    
    $self->post_event( $self->event , Storable::freeze($message) );
    return;
}

sub TO_JSON { 
    ## really should be the canonical identity
    my $self = shift;
    my $ref = {  %$self }       ;
    $ref->{__origin_class} = ref $self;
    $ref;
}

1;