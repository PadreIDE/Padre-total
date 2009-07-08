package Padre::Swarm::Transport;
use strict;
use warnings;
use Carp qw( croak );
use Params::Util qw( _POSINT _STRING _INSTANCE );
use IO::Select;
use Class::XSAccessor
    accessors => {
        subscriptions => 'subscriptions',
        channels => 'channels',
        selector => 'selector',
        started  => 'started',
    };

sub new {
    my ($class,%args) = @_;
    my %obj = %args;
    my $selector = IO::Select->new();
    $obj{subscriptions} = {};
    $obj{channels}      = {};
    $obj{started}       = 0;
    $obj{selector}      = $selector;
    
    return bless \%obj , ref $class || $class;
}


sub subscribe_channel {
    my ($self,$channel,$loopback) = @_;
    $loopback = 1 unless defined $loopback;
    if ( _POSINT $channel && $channel <= 65535 ) 
    {
        $self->subscriptions->{$channel} = $loopback;
        $self->_connect_channel($channel,$loopback) if $self->started ;
    }
    else {
        croak "'$channel' is not a valid channel"; 
    }
    return 1;
}

sub unsubscribe_channel {
    my ($self,$channel) = @_;
    if ( _POSINT $channel && $channel <= 65535 )
    {
        delete $self->subscriptions->{$channel};
        $self->_shutdown_channel($channel);
    }
    else {
        croak "'$channel' is not a valid channel";
    }
}

## Curry a callback from self-> 
SCOPE: {
 my %callbacks;   
 
 sub cb {
    my $instance = shift;
    my $method   = shift;
    
    croak 'You cannot raise a callback to a class. Pass an object instance'
        unless _INSTANCE( $instance , __PACKAGE__ );
    croak 'You must pass a valid method name' 
        unless _STRING( $instance );

    my $signature = sprintf('%s/%s', $instance, $method );
    
    croak "You cannot callback to '$method'. '$instance' has no such method"
        unless $instance->can( $method );
        
    if ( exists $callbacks{"$signature"} ) {
        return $callbacks{"$signature"};
    }
    else {
        my $cb = sub { $instance->$method( @_ ) };
        $callbacks{"$signature"} = $cb; 
        return $cb;
    }
 }

} # SCOPE:

1;