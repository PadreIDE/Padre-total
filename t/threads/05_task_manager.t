#!/usr/bin/perl

# Create the task manager

use strict;
use warnings;
use Test::More tests => 9;
use Test::NoWarnings;
use Time::HiRes 'sleep';
use Padre::Logger;
use Padre::Task2Manager ();

# Do we start with no threads as expected
is( scalar(threads->list), 0, 'No threads' );




######################################################################
# Basic Creation

SCOPE: {
	my $manager = Padre::Task2Manager->new;
	isa_ok( $manager, 'Padre::Task2Manager' );
	is( scalar(threads->list), 0, 'No threads' );

	# Run the startup process
	ok( $manager->start, '->start ok' );
	sleep 0.1;
	is( scalar(threads->list), 3, 'Three threads exists' );

	# Run the shutdown process
	ok( $manager->stop, '->stop ok' );
	sleep 0.1;
	is( scalar(threads->list), 0, 'No threads' );
}

# Do we start with no threads as expected
is( scalar(threads->list), 0, 'No threads' );
