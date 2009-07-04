package Padre::Swarm::Identity;
use strict;
use warnings;
use Carp qw( croak );
use Params::Util qw( _STRING );

use Class::XSAccessor 
	constructor => 'new',
	getters => {
		nickname => 'nickname',
		transport=> 'transport',
		service  => 'service',
		resource => 'resource',
		identity => 'identity',
		canonical=> 'canonical',
	};

=pod

=head1 NAME

Padre::Swarm::Identity - represent a unique identity in the swarm

=head1 SYNOPSIS

  my $id = $message->identity;
  printf( '%s @[%s] using resource %s on service %s',
	$id->nickname, $id->transport,
	$id->resource, $id->service );
  my $swarm_id = $id->canonical;
  

=head1 DESCRIPTION

Attempt to make anything and everything addressable. More work needed.


=cut


sub is_valid {
	my $self = shift;
	defined $self->{canonical};
}

sub set_nickname {
	my $self = shift;
	my $arg  = shift;
	my ($nickname) = 
		$arg   =~ /([^\W!])/;
	croak "Invalid nickname '$arg'" unless $nickname;
	$self->{nickname} = $nickname;
	$self->{canonical}= $self->_canonise;
	
}

sub set_transport {
	
}