package Padre::Swarm::Transport;
use strict;
use warnings;
use Carp qw( croak );
use Params::Util qw( _POSINT );
use Class::XSAccessor
    accessors => {
        subscriptions => 'subscriptions',
        channels => 'channels',
        selector => 'selector',
        started  => 'started',
    };

sub new {
    my ($class,%args) = @_;
    my %obj;
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



1;