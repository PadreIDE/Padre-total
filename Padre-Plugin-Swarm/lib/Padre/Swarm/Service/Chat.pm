package Padre::Swarm::Service::Chat;

use strict;
use warnings;
use JSON::XS;
use Time::HiRes ();
use Padre::Swarm::Transport::Multicast ();
use Padre::Swarm::Service ();
use Padre::Swarm::Message ();
use Params::Util qw( _INSTANCE );
use Carp qw( croak confess carp );
use Data::Dumper;

my $marshal = 
JSON::XS
    ->new
    ->allow_blessed
    ->convert_blessed
    ->utf8
    ->filter_json_object(\&synthetic_class );
    
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
    

    
    Padre::Util::debug('Channels subscribed');
    $self->transport->start; 
    Time::HiRes::sleep(0.5); # QUACKERY.. socket construction?
    $self->queue->enqueue(
        Padre::Swarm::Message->new( {
            type=>'disco' , want=>['chat'] })
    );
    
    $self->queue->enqueue(Padre::Swarm::Message->new(  {type=>'announce'} ) );
    
}

sub service_loop {
    my ($self,$message) = @_;
    Padre::Util::debug("Service [$self] loop!\n") ;
    my $queue = $self->queue;
    #Padre::Util::debug("\t$queue " . $queue->pending , $/);
    if ( _INSTANCE( $message, 'Padre::Swarm::Message' ) ){
        warn "Chat send $message";
        $self->send( $message );
    }
    elsif( ref $message ) {
            carp "Was asked to pass $message - " . Dumper $message;
            
    }
    
    if ( my @ready =  $self->transport->poll(0.5) ) {
        Padre::Util::debug("Transport has ready = " . @ready );
        my @messages;
        push @messages,
            $self->transport->receive_from_channel($_)
                for @ready;
          while ( my ($payload,$frame) = splice(@messages,0,2) ) {
            #warn 'Decoding ' , Dumper $payload;
            my $message = eval { $marshal->decode( $payload ); };

            
            unless ($message) {
                warn "Decode failed for $payload \n\t - with $@";
                #$self->task_warn($@ );
                #$self->task_warn($payload);
                next;
            }
            
            warn "DECODED " . Dumper $message;
            
            $message->{$_} = $frame->{$_}
                for keys %$frame;
                
            eval { $self->receive( $message ) };
            warn "FAILED receive $@" if $@;
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
        Padre::Swarm::Message->new( body => $text)
    );
}

sub say_to {
    my ($self,$text,$entity) = @_;
    my $msg = Padre::Swarm::Message->new(
        body => $text ,
        to => $entity,
    );
    
    $self->send( $msg );
}

sub send {
    my ($self,$message) = @_;
    if (ref $message) {
        confess "pass a Padre::Swarm::Message" 
            unless _INSTANCE( $message, 'Padre::Swarm::Message'  );
        warn Dumper $message;
        
        $message->from( 'unspecified' ) 
            unless  $message->from;
        $message->type( 'chat' ) unless $message->type;
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
    $self->send(
        Padre::Swarm::Message->new({type=>'promote', service=>"$self"})
    );

    
}


sub receive {
    my $self = shift;
    my $message = shift;
    confess "Did not receive a message!"
        unless ( _INSTANCE( $message, 'Padre::Swarm::Message' ) );

    my $type = $message->type;
    $type ||= '';
    
    if ( $type eq 'disco' ) {
        warn "DISCO recv";
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
    
    #confess "SYNTHESISING ! " . Dumper @_; 
    my $var = shift ;
    if ( exists $var->{__origin_class} ) {

        my $instance = bless $var , $var->{__origin_class};
        return $instance;
    }
    return $var;
};



1;