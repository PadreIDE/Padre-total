#!/usr/bin/perl

# Enforce higher standards against code that will be installed

use strict;
use warnings;
use Test::More;
use File::Spec::Functions ':ALL';

BEGIN {

	# Don't run tests for installs or automated tests
	unless ( $ENV{RELEASE_TESTING} ) {
		plan( skip_all => "Author tests not required for installation" );
	}
	my $config = catfile( 'xt', 'critic-core.ini' );
	unless ( eval "use Test::Perl::Critic -profile => '$config'; 1" ) {
		plan skip_all => 'Test::Perl::Critic required to criticise code';
	}
}

# need to skip t/files and t/collection
all_critic_ok(
	'blib/lib/Padre.pm',
	'blib/lib/Padre',
	'blib/lib/Wx',
	'blib/script'
);
