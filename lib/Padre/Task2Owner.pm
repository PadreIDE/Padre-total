package Padre::Task2Owner;

=pod

=head1 NAME

Padre::Task2Owner - A role for objects that commission tasks

=head1 DESCRIPTION

This is a role that should be inherited from by objects in Padre's
permanent model that want to commision tasks to be run and have the
results fed back to them, if the answer is still relevant.

=cut

use 5.008005;
use strict;
use warnings;
use Scalar::Util ();

our $VERSION = '0.62';

# Use a shared sequence for object revisioning greatly
# simplifies the indexing process.
my $SEQUENCE = 0;
my %INDEX    = ();





######################################################################
# Statefulness

# Get the object's current revision
sub revision {
	my $self = shift;

	# Set a revision if this is the first time
	unless ( defined $self->{revision} ) {
		$self->{revision} = ++$SEQUENCE;
	}

	# Optimisation hack: Only populate the index when
	# the revision is queried from the view.
	unless ( exists $INDEX{$self->{revision}} ) {
		$INDEX{$self->{revision}} = $self;
		Scalar::Util::weaken($INDEX{$self->{revision}});
	}

	return $self->{revision};
}

# Object state has changed, update revision and flush index.
sub revision_change {
	my $self = shift;
	if ( $self->{revision} ) {
		delete $INDEX{$self->{revision}};
	}
	$self->{revision} = ++$SEQUENCE;
}

# Locate an object by revision
sub revision_fetch {
	$INDEX{$_[1]};
}

1;

=pod

=head1 COPYRIGHT & LICENSE

Copyright 2008-2010 The Padre development team as listed in Padre.pm.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut

# Copyright 2008-2010 The Padre development team as listed in Padre.pm.
# LICENSE
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl 5 itself.
