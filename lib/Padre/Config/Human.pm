#
# Configuration and state data relating to the human using Padre.
#

package Padre::Config::Human;

use 5.008;
use strict;
use warnings;

use Carp          qw{ croak              };
use Params::Util  qw{ _HASH0             };
use Storable      qw{ dclone             };
use YAML::Tiny    qw{ DumpFile LoadFile  };

use Padre::Config::Constants qw{ $CONFIG_FILE_USER };

our $VERSION = '0.32';

my $REVISION = 1;		# config schema revision


# -- constructors

#
# my $config = Padre::Config::Human->_new( $href );
#
# create & return a new config object. if $href is not supplied, the config
# object will be empty. this constructor is private and should not be used
# outside this class.
#
sub _new {
	my ($class, $self) = @_;
	$self ||= {};
	bless $self, $class;
	return $self;
}


#
# my $config = Padre::Config::Human->create;
#
sub create {
	my $class = shift;
	my $self  = $class->_new( { version => $REVISION } );
	$self->write;
	return $self;
}


#
# my $config = Padre::Config::Human->read;
#
sub read {
	my $class = shift;

	# Load the user configuration
	my $hash = eval { LoadFile( $CONFIG_FILE_USER ) };
	return unless _HASH0($hash);

	# Create and return the object
	return $class->_new($hash);
}


# -- public methods

#
# my $revision = $config->version;
#
sub version {
	my $self = shift;
	$self->{version};	# stored as other preferences!
}


#
# $config->write;
#
sub write {
	my $self = shift;

	# Clone and remove the bless
	my $copy = dclone( +{ %$self } );

	# Save the user configuration
	DumpFile( $CONFIG_FILE_USER, $copy );

	return 1;
}


1;

__END__

=head1 NAME

Padre::Config::Human - Padre configuration storing personal preferences


=head1 DESCRIPTION

This class implements the personal preferences of Padre's users. See C<Padre::Config>
for more information on the various types of preferences supported by Padre.

All human settings are stored in a hash as top-level keys (no hierarchy). The hash is
then dumped in C<config.yml>, a YAML file in Padre's preferences directory (see
C<Padre::Config>). 


=head1 PUBLIC API

=head2 Constructors

=over 4

=item my $config = Padre::Config::Human->create;

Create & return an empty user configuration. (almost empty, since it will
still store the config schema revision - see version() below).

No params.


=item my $config = Padre::Config::Human->read;

Load & return the user configuration from the yaml file. Return undef in
case of failure.

No params.


=back


=head2 Object methods

=over 4

=item my $revision = $config->version;

Return the config schema revision. Indeed, we might want to have
more structured config instead of a plain hash later on. Note that this
version is stored with the other user preferences at the same level.

No params.


=item $config->write;

(Over-)write user configuration to the yaml file.

No params.

=back


=head1 COPYRIGHT & LICENSE

Copyright 2008-2009 The Padre development team as listed in Padre.pm.

This program is free software; you can redistribute it and/or modify it under the
same terms as Perl 5 itself.

=cut

# Copyright 2008-2009 The Padre development team as listed in Padre.pm.
# LICENSE
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl 5 itself.
