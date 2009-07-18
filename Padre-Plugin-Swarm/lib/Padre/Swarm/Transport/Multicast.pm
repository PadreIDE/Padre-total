package Padre::Swarm::Transport::Multicast;
use strict;
use warnings;

use IO::Select       ();
use IO::Socket::Multicast;
use Padre::Swarm::Identity;
use Padre::Swarm::Transport;
use Params::Util     qw( _INSTANCE _POSINT );
use Carp             qw( confess croak     );
use Class::XSAccessor
    accessors => {
        subscriptions => 'subscriptions',
        channels => 'channels',
        selector => 'selector',
        started  => 'started',
        sockets  => 'sockets',
    };

use constant MCAST_GROUP => '239.255.255.1';

our @ISA = 'Padre::Swarm::Transport';

=pod

=head1 NAME

Padre::Swarm::Transport::Multicast

=head1 SYNOPSIS

  my $transport = Padre::Swarm::Transport::Multicast->new();
  $transport->subscribe_channel( 20000 ) or die $!;
  $transport->subscribe_channel( 22000 ) or die $!;
  
  $transport->start;
  if ( $transport->started ) {
      $transport->tell_channel( 22000, 'Hello World!' );
  }
  
  foreach my $channel ( $transport->poll ) {
      my $payload = $transport->receive_from( $channel );
      # do something exciting w/ $payload
   };
  
  $transport->unsubscribe_channel( 20000 );
  $transport->shutdown;
  
=head1 METHODS

=head2 start

=head2 shutdown

=head2 started

=head2 subscribe_channel

=head2 unsubscribe_channel

=head2 poll

=head2 receive_from

=head2 tell_channel


=cut

sub new {
    my ($class,%args) = @_;
    my %obj;
    my $selector = IO::Select->new();
    $obj{subscriptions} = {};
    $obj{channels}      = {};
    $obj{sockets}       = {};
    $obj{started}       = 0;
    $obj{selector}      = $selector;
    
    return bless \%obj , ref $class || $class;
}

sub transport_name { 'multicast' }

sub start {
    my ($self) = @_;
    croak "Transport already started" if $self->started;
    while ( my ($channel,$loopback) = each %{ $self->subscriptions } ) {
        $self->_connect_channel( $channel, $loopback );
    }
    return $self->started( 1 );
}

sub shutdown {
    my ($self) = @_;
    croak "Transport is not started" unless $self->started;
    while ( my ($channel,$socket) = each %{ $self->channels } ) {
        $self->_shutdown_channel( $channel );
    }
    $self->started(0);
    return 1;
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

sub poll {
    my ($self,$timeout) = @_;
    $timeout ||= 0;
    warn "Polling before service start!!" unless $self->started;
    my @socks =  $self->selector->can_read($timeout);
    my @channels = map { $self->sockets->{"$_"} } @socks;
    return @channels;
}

sub tell_channel {
    my ($self,$channel,$payload) = @_;
    if ( _POSINT $channel && $channel <= 65535 ) {
        my $sock = $self->channels->{$channel};
        $sock->mcast_send( $payload ,
            MCAST_GROUP . ':' . $channel
        ) or die "Failed mcast send $!";
    }
    else {
        croak "'$channel' is not a valid channel";
    }
}

sub receive_from_channel {
    my ($self,$channel) = @_;
    if ( exists $self->channels->{$channel} ) {
        my $sock = $self->channels->{$channel};
        return $self->receive_from_sock( $sock );
    }
    else {
        croak "No such channel '$channel'";
    }
}

sub receive_from_sock {
    my ($self,$sock) = @_;
    my $buffer;
    my $remote = $sock->recv( $buffer, 65535 );
    if  ( $remote ) {
        #warn "Got remote of '$remote'";
        my ($rport,$raddr) = sockaddr_in $remote;
        my $ip = inet_ntoa $raddr;
        return ($buffer,
            {  port=>$rport,address=>$ip ,
               timestamp => time() # yuk UTC in a portable way how
                }
            
            );
    }
    else { return }
}

sub _connect_channel  {
    my ($self,$port,$loopback) = @_;
    confess "Socket '$port' already connected" 
        if exists $self->channels->{$port};
    my $socket = IO::Socket::Multicast->new(
            LocalPort => $port,
            ReuseAddr => 1,
    );
    $socket->mcast_add( MCAST_GROUP );
    $socket->mcast_loopback( $loopback );
    $self->channels->{$port} = $socket;
    $self->selector->add( $socket );
    $self->sockets->{"$socket"} = $port;
    return 1;
}

sub _shutdown_channel {
    my ($self,$port) = @_;
    my $socket = delete $self->channels->{$port};
    return 1 unless defined $socket;
    delete $self->subscriptions->{$port};
    delete $self->sockets->{"$socket"};
    $self->selector->remove( $socket );
    $socket->mcast_drop( MCAST_GROUP );
    $socket->shutdown(0);
    undef $socket;
    return 1;
}

1;