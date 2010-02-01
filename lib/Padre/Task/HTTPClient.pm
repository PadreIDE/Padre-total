package Padre::Task::HTTPClient;

use 5.008;
use strict;
use warnings;

use Padre::Constant;

# Use all modules which may provide services for us:

our $VERSION = '0.56';

=pod

=head1 NAME

Padre::Task::HTTPClient - HTTP client for Padre

=head1 DESCRIPTION

C<Padre::Task::HTTPClient> provides a common API for HTTP access to Padre.

As we don't want a specific HTTP client module dependency to a
network-independent application like Padre, this module searches
for installed HTTP client modules and uses one of them.

If none of the "child" modules could be loaded (no HTTP support at all
on this computer), it fails and returns nothing (scalar C<undef>).

=head1 METHODS

=head2 new

  my $http = Padre::Task::HTTPClient->new();

The C<new> constructor lets you create a new C<Padre::Task::HTTPClient> object.

Returns a new C<Padre::Task::HTTPClient> or dies on error.

=cut

sub new {

	my $class = shift;

	my %args = @_;

	return if ( !defined( $args{URL} ) ) or ( $args{URL} eq '' );

	# Prepare information
	$args{headers}->{'X-Padre'} ||= 'Padre version ' . $VERSION . ' ' . Padre::Constant::PADRE_REVISION;
	$args{method} ||= 'GET';

	my $self;

	# Each module will be tested and the first working one should return
	# a object, all others should return nothing (undef)
	for ('LWP') {

		#		require 'Padre/Task/HTTPClient/' . $_ . '.pm';
		eval 'require Padre::Task::HTTPClient::' . $_;
		next if $@;
		$self = "Padre::Task::HTTPClient::$_"->new(%args);
		next unless defined($self);
		return $self;
	}

	return;

}

#=head2 atime
#
#  $file->atime;
#
#Returns the last-access time of the file.
#
#This is usually not possible for non-local files, in these cases, undef
#is returned.
#
#=cut
#
## Fallback if the module has no such function:
#sub atime {
#	return;
#}
#
1;

# Copyright 2008-2010 The Padre development team as listed in Padre.pm.
# LICENSE
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl 5 itself.
