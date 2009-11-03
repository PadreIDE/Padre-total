package Padre::Service::Swarm;

use strict;
use warnings;
use Padre::Wx      ();
use Padre::Service ();
use Padre::Swarm::Service::Chat;

our $VERSION = '0.03';
our @ISA     = 'Padre::Service';

use Class::XSAccessor
	accessors => {
		task_event => 'task_event',
		service    => 'service',
	};

=pod

=head1 Padre::Service::Swarm - Buzzing Swarm!

Join the buzz , schedule a Swarm service to throw a event at you 
when something interesting happens.

=head1 SYNOPSIS

=head1 METHODS

=cut

sub hangup {
	my $self = shift;
	$self->service->shutdown;
}

sub terminate {
	my $self = shift;
	my $service = $self->service(undef);
	undef $service;
}

SCOPE: {
	my $service;
	sub service_loop {
		my $self = shift;
		unless ( defined $service ) {
			$service = $self->service->new;
			$service->start;
		}
		
		if (my $message = $service->receive(0.2) ) {
			$self->handle_message($message);
		}
		
		return 1;
	}
}

sub handle_message {
	my $self = shift;
	my $message = shift;
	#my $data = Storable::freeze($message);
	my $ev = $self->task_event;
	$self->post_event( 
		$self->task_event, 
		#$data,
		$message
	);
}

1;

# Copyright 2008-2009 The Padre development team as listed in Padre.pm.
# LICENSE
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl 5 itself.
