package Padre::Task::Buzz;

use strict;
use warnings;
use Padre::Task ();
use Padre::Wx   ();
use Class::Autouse ();
use Padre::Swarm::Service::Chat;
use Data::Dumper;

our $VERSION = '0.38';
our @ISA     = 'Padre::Task';

use Class::XSAccessor
	accessors => {
		task_event=>'task_event',
		service => 'service',
	};
	


#sub new {
#	my ($class,@args) = @_;
#	my $self = $class->SUPER::new(@args);
#	my $running : shared = 0;
#	$self->{running} = $running;
#}
#
=pod

=head1 Padre::Task::Buzz - Buzzing Swarm!

Join the buzz , schedule a Swarm:: service to throw a event at you 
when something interesting happens.

=head1 SYNOPSIS



=head1 METHODS


=cut

# set up a new event type

our $registered = undef;
sub prepare {
	my $self = shift;
	my $running : shared = 0;
	$self->{running} = $running;

	return;
}

sub running { 
	my $self = shift;
	my $value= shift;
	if (defined $value) {
		return $self->{running} = $value;
	}
	else {
		return $self->{running};
	}
}

sub run {
	my $self = shift;
	$self->running( 1 );
	#Class::Autouse->autouse( $self->service );
	my $service = $self->service->new;
	$service->start;
	
	while ( $self->running ) {
			while (my $message = $service->receive(0.2) ) {
				$self->handle_message($message);
			}
		
	}
	$service->shutdown;
	
	return 1;
}

sub handle_message {
	my $self = shift;
	my $message = shift;
	my $data = Storable::freeze($message);
	my $ev = $self->task_event;
	$self->post_event( 
		$self->task_event, 
		$data,
	);
}

1;

__END__

# Copyright 2008-2009 The Padre development team as listed in Padre.pm.
# LICENSE
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl 5 itself.
