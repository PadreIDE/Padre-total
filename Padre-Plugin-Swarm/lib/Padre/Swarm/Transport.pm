package Padre::Swarm::Transport;

=pod

=head1 NAME

Padre::Swarm::Transport - Swarm network transport

=head1 SYNOPSIS

  my $t = Padre::Swarm::Transport->new();
  $t->subscribe_channel( 65000 );
  $t->start;
  my $data = 'Hello world!';
  $t->tell_channel( 65000 => $data );
  
  my @incoming;
  my @channels = $t->poll(1);
  foreach my $channel ( @channels ) {
    my ($payload,$frame) = $t->receive_from_channel( $channel );
    next if $frame->{address} = $MY_ADDRESS;
    push @incoming , $payload;
  }

=head1 DESCRIPTION

Generic class describing the interface for a Padre::Swarm::Transport

=head1 METHODS

=cut

use strict;
use warnings;
use Carp qw( croak confess );
use Params::Util qw( _POSINT _STRING _INSTANCE );
use IO::Select;
use Padre::Plugin::Swarm ();
use Padre::Swarm::Callback;

our $VERSION = '0.04';

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

use constant DEBUG => Padre::Plugin::Swarm::DEBUG;

sub new {
    my ($class,%args) = @_;
    my %obj = %args;
    my $selector = IO::Select->new();
    confess "Requires identity"
        unless _INSTANCE( $obj{identity} , 'Padre::Swarm::Identity' );
    
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
    if ( _POSINT $channel && $channel <= 65535 ) {
        $self->subscriptions->{$channel} = $loopback;
        $self->_connect_channel($channel,$loopback) if $self->started ;
    } else {
        croak "'$channel' is not a valid channel"; 
    }
    return 1;
}

sub unsubscribe_channel {
    my ($self,$channel) = @_;
    if ( _POSINT $channel && $channel <= 65535 ) {
        delete $self->subscriptions->{$channel};
        $self->_shutdown_channel($channel);
    } else {
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
    warn "GENERATED callback $cb" if DEBUG;
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
	# else { warn "Drained '$channel' buffer" if DEBUG; }

	return @$d;
}

sub transport_name { die };

sub tell_channel { die };

sub poll { die };

1;
