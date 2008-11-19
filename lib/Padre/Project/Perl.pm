package Padre::Project;

# This is not usable yet

use strict;
use warnings;
use File::Spec        ();
use Module::Inspector ();

use base 'Module::Inspector';

our $VERSION = '0.17';

sub from_file {
	my $class = shift;

	# Check the file argument
	my $focus_file = shift;
	unless ( -f $focus_file ) {
		return;
	}

	# Search upwards from the file to find the project root
	my ($v, $d, $f) = File::Spec->splitpath($focus_file);
	my @d = File::Spec->splitdir($d);
	pop @d if $d[-1] eq '';
	my $dirs = List::Util::first {
			-f File::Spec->catpath( $v, $_, 'Makefile.PL' )
			or
			-f File::Spec->catpath( $v, $_, 'Build.PL' )
		}
		map {
			File::Spec->catdir(@d[0 .. $_])
		} reverse ( 0 .. $#d );
	unless ( defined $dirs ) {
		# Carp::croak("Failed to find the portable.perl file");
		return;
	}

	# Hand off to the regular constructor
	return $class->new(
		dist_dir => File::Spec->catpath( $v, $dirs ),
	);
}

1;

# Copyright 2008 Gabor Szabo.
# LICENSE
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl 5 itself.
