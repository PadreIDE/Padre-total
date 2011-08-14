package Padre::Plugin::Swarm::Transport::Local;
use strict;
use warnings;
use Padre::Logger;
use Data::Dumper;
use base qw( Object::Event );
use AnyEvent::Handle;
use IO::Socket::Multicast;
use JSON;
our $VERSION = '0.11';

sub new {
    my $class = shift;
    my $self = $class->SUPER::new(@_);
    $self->{token} = $$.rand();
    return $self;
}

sub enable {
    my  $self = shift;
    
    my $m = IO::Socket::Multicast->new(
                LocalPort => 12000,
                ReuseAddr => 1,
    ) or die $!;
    
    $m->mcast_add('239.255.255.1'); #should have the interface
    $m->mcast_loopback( 1 );
    
    $self->{m} = $m;
    $self->{io} = AnyEvent->io(
        fh => $m,
        poll => 'r',
        cb => sub {
             $self->event('readable') 
        }
    );
    $self->reg_cb( 'readable' , \&readable );
    $self->event('connect',1);
    
    return;
}

sub send {
    my $self = shift;
    my $message = shift;
    $message->{token} = $self->{token};
    my $data = eval { $self->_marshal->encode($message) };
    if ($data) {
        $self->{m}->mcast_send(
            $data, '239.255.255.1:12000'
        );
    }
}

sub readable {
    my $self = shift;
    my $data;
    $self->{m}->recv($data,65535);
    TRACE( "Received data $data") if DEBUG;
    my $message = eval{ $self->_marshal->decode($data) };
    
    if ( $message ) {
        $self->event('recv', $message);
    }
    
}

sub _marshal {
	JSON->new
	    ->allow_blessed
            ->convert_blessed
            ->utf8
            ->filter_json_object(\&synthetic_class );
}


sub synthetic_class {
	my $var = shift ;
	if ( exists $var->{__origin_class} ) {
		my $stub = $var->{__origin_class};
		my $msg_class = 'Padre::Swarm::Message::' . $stub;
		my $instance = bless $var , $msg_class;
		return $instance;
	} else {
		return bless $var , 'Padre::Swarm::Message';
	}
};


1;
