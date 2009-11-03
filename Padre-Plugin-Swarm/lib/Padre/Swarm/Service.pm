package Padre::Swarm::Service;

use strict;
use warnings;
use Carp qw( croak );
use Padre::Service ();

our $VERSION = '0.03';
our @ISA     = 'Padre::Service';

sub identity {
	my $self = shift;
	return (exists $self->{identity}) 
		? $self->{identity}
		: undef;
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

sub ping {
	
}

sub _attach_transports {
	my ($self) = @_;
	croak "No use_transport defined" unless exists $self->{use_transport};
	my $transports = $self->{use_transport};

	while ( my ($class,$args) = each %$transports ) {
		eval "require $class;";
		my $transport = $class->new( %$args );
		$self->set_transport( $transport );
	}
	foreach ( $self->service_channels ) {
		$self->transport->subscribe_channel( $_ , 1 );
	}
}

1;
