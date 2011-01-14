package Padre::Config::Human;

# Configuration and state data relating to the human using Padre.

use 5.008;
use strict;
use warnings;
use Storable        ();
use YAML::Tiny      ();
use Params::Util    ();
use Padre::Constant ();

our $VERSION = '0.78';

# Config schema revision
my $REVISION = 1;

#
# my $config = Padre::Config::Human->create;
#
sub create {
	my $class = shift;
	my $self = bless { version => $REVISION }, $class;
	$self->write;
	return $self;
}

#
# my $config = Padre::Config::Human->read;
#
sub read {
	my $class = shift;

	# Load the user configuration
	my $hash = -e Padre::Constant::CONFIG_HUMAN ? eval { YAML::Tiny::LoadFile(Padre::Constant::CONFIG_HUMAN) } : {};
	unless ( Params::Util::_HASH0($hash) ) {
		return;
	}

	# Create and return the object
	return bless $hash, $class;
}

# -- public methods

#
# my $revision = $config->version;
#
sub version {
	$_[0]->{version};
}

#
# $config->write;
#
sub write {
	my $self = shift;

	# Save the unblessed clone of the user configuration hash
	YAML::Tiny::DumpFile(
		Padre::Constant::CONFIG_HUMAN,
		Storable::dclone( +{%$self} ),
	);

	return 1;
}

1;

__END__

=pod

=head1 NAME

Padre::Config::Human - Padre configuration storing personal preferences

=head1 DESCRIPTION

This class implements the personal preferences of Padre's users. See L<Padre::Config>
for more information on the various types of preferences supported by Padre.

All human settings are stored in a hash as top-level keys (no hierarchy). The hash is
then dumped in F<config.yml>, a L<YAML> file in Padre's preferences directory (see
L<Padre::Config>).

=head1 PUBLIC API

=head2 Constructors

=over 4

=item create

    my $config = Padre::Config::Human->create;

Create and return an empty user configuration. (Almost empty, since it will
still store the configuration schema revision - see L</"version">).

No parameters.

=item read

    my $config = Padre::Config::Human->read;

Load & return the user configuration from the YAML file. Return C<undef> in
case of failure.

No parameters.

=back

=head2 Object methods

=over 4

=item version

    my $revision = $config->version;

Return the configuration schema revision. Indeed, we might want to have
more structured configuration instead of a plain hash later on. Note that this
version is stored with the other user preferences at the same level.

No parameters.

=item write

    $config->write;

(Over-)write user configuration to the YAML file.

No parameters.

=back

=head1 COPYRIGHT & LICENSE

Copyright 2008-2011 The Padre development team as listed in Padre.pm.

This program is free software; you can redistribute it and/or modify it under the
same terms as Perl 5 itself.

=cut

# Copyright 2008-2011 The Padre development team as listed in Padre.pm.
# LICENSE
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl 5 itself.
