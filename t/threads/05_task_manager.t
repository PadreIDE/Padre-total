#!/usr/bin/perl

# Create the task manager

use strict;
use warnings;
use Test::More tests => 5;
use Test::NoWarnings;
use Time::HiRes 'sleep';
use Padre::Logger;
use Padre::Task2Manager ();





######################################################################
# Basic Creation

SCOPE: {
	my $manager = Padre::Task2Manager->new;
	isa_ok( $manager, 'Padre::Task2Manager' );
}
