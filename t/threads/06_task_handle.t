#!/usr/bin/perl

# Spawn and then shut down the task worker object.
# Done in similar style to the task master to help encourage
# implementation similarity in the future.

#BEGIN {
#$Padre::Task2Master::DEBUG = 1;
#$Padre::Task2Thread::DEBUG = 1;
#}

use strict;
use warnings;
use Test::More tests => 24;
use Test::NoWarnings;
use Padre::Task2Handle     ();
use Padre::Task2::Addition ();
use Padre::Logger;





######################################################################
# Check the raw task

SCOPE: {
	my $addition = Padre::Task2::Addition->new(
		x => 2,
		y => 3,
	);
	isa_ok( $addition, 'Padre::Task2::Addition' );
	is( $addition->{x}, 2, '->{x} matches expected' );
	is( $addition->{y}, 3, '->{y} matches expected' );
	is( $addition->{z}, undef, '->{z} matches expected' );

	# Run the task
	is( $addition->prepare, 1, '->prepare ok' );
	is( $addition->run,     1, '->run ok'     );
	is( $addition->finish,  1, '->finish ok'  );
	is( $addition->{x},     2, '->{x} matches expected' );
	is( $addition->{y},     3, '->{y} matches expected' );
	is( $addition->{z},     5, '->{z} matches expected' );

	# Check round-trip serialization
	my $string = $addition->serialize;
	ok(
		(defined $string and ! ref $string and length $string),
		'->serialize ok',
	);
	my $round = Padre::Task2::Addition->deserialize( $string );
	isa_ok( $round, 'Padre::Task2::Addition' );
	is_deeply( $round, $addition, 'Task round-trips ok' );
}





######################################################################
# Run the task via a handle object

SCOPE: {
	my $handle = Padre::Task2Handle->new(
		Padre::Task2::Addition->new(
			x => 2,
			y => 3,
		)
	);
	isa_ok( $handle, 'Padre::Task2Handle' );
	isa_ok( $handle->task, 'Padre::Task2::Addition' );
	is( $handle->hid, 1, '->hid ok' );
	is( $handle->task->{x}, 2, '->{x} matches expected' );
	is( $handle->task->{y}, 3, '->{y} matches expected' );
	is( $handle->task->{z}, undef, '->{z} matches expected' );

	# Run the task
	is( $handle->run, 1, '->run ok'     );
	is( $handle->task->{x}, 2, '->{x} matches expected' );
	is( $handle->task->{y}, 3, '->{y} matches expected' );
	is( $handle->task->{z}, 5, '->{z} matches expected' );
}
