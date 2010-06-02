package Padre::Config::Project;

# Configuration and state data that describes project policies.

use 5.008;
use strict;
use warnings;
use File::Basename ();
use YAML::Tiny     ();
use Params::Util   ();

our $VERSION = '0.63';





######################################################################
# Constructor

use Class::XSAccessor {
	constructor => 'new',
	getters     => {
		dirname  => 'dirname',
		fullname => 'fullname',
	},
};

# TO DO Write constructor that checks the config?

sub read {
	my $class = shift;

	# Check the file
	my $fullname = shift;
	unless ( defined $fullname and -f $fullname and -r $fullname ) {
		return;
	}

	# Load the user configuration
	my $hash = YAML::Tiny::LoadFile($fullname);
	return unless Params::Util::_HASH0($hash);

	# Create the object, saving the file name and directory for later usage
	my $dirname = File::Basename::dirname($fullname);
	return $class->new(
		%$hash,
		dirname  => $dirname,
		fullname => $fullname,
	);
}

# NOTE: Once we add the ability to edit the project settings, make sure
# we strip out the path value before we save them.

1;

# Copyright 2008-2010 The Padre development team as listed in Padre.pm.
# LICENSE
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl 5 itself.
