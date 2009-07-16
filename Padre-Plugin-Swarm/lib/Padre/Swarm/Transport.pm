package Padre::Swarm::Transport;
use strict;
use warnings;
use Carp qw( croak confess );
use Params::Util qw( _POSINT _STRING _INSTANCE );
use Padre::Swarm::Callback;

use IO::Select;
use Class::XSAccessor
    accessors => {
        subscriptions => 'subscriptions',
        channels => 'channels',
        identity => 'identity',
        selector => 'selector',
        started  => 'started',
        loopback => 'loopback',
        condvar  => 'condvar',
    };

sub new {
    my ($class,%args) = @_;
    my %obj = %args;
    my $selector = IO::Select->new();
    $obj{subscriptions} = {};
    $obj{channels}      = {};
    $obj{started}       = 0;
    $obj{selector}      = $selector;
    $obj{incoming_buffer} = {};
    $obj{outgoing_buffer} = {};
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

sub cb {
    my $instance = shift;
    my @args = @_;

    confess  'You cannot raise a callback to a class. Pass an object instance'
        unless _INSTANCE( $instance , __PACKAGE__ );

    my $cb = Padre::Swarm::Callback::GENERATE(
        $instance, @args
    );
    warn "GENERATED callback $cb";
    return $cb
}


sub push_write {
    my ($self,$channel,$message) = @_;
    push @{ $self->{outgoing_buffer}{$channel} } , $message;
    
}

sub start { die }

sub shutdown { die };


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

sub transport_name { die };


sub tell_channel { die };

sub poll { die };



1;