#!/usr/bin/perl

# Spawn and then shut down the task master object

use strict;
use warnings;
use Test::More tests => 18;
use Test::NoWarnings;
use Padre::Task2Master;
use Padre::Task2Worker;
use Devel::Dumpvar;
use Diagnostics;

# Do we start with the one thread we expect
is( scalar(threads->list), 0, 'One thread exists' );





######################################################################
# Simplistic Start and Stop

SCOPE: {
	# Create the master thread
	my $master = Padre::Task2Master->new->spawn;
	isa_ok( $master, 'Padre::Task2Master' );
	isa_ok( $master->queue, 'Thread::Queue' );
	isa_ok( $master->thread, 'threads' );
	ok( ! $master->is_thread, '->is_thread is false' );
	my $tid = $master->thread->tid;
	ok( $tid, "Got thread id $tid" );

	# Does the threads module agree it was created
	my @threads = threads->list;
	is( scalar(@threads), 1, 'Found one thread' );
	is( $threads[0]->tid, $tid, 'Found the expected thread id' );

	# Initially, the thread should be running
	ok( $master->is_running, 'Master is_running' );
	ok( ! $master->is_joinable, 'Master is not is_joinable' );
	ok( ! $master->is_detached, 'Master is not is_detached' );

	# It should stay running
	diag("Pausing to allow clean thread startup...");
	sleep 1;
	ok(   $master->is_running,  'Master is_running' );
	ok( ! $master->is_joinable, 'Master is not is_joinable' );
	ok( ! $master->is_detached, 'Master is not is_detached' );

	# Instruct the master to shutdown, and give it a brief time to do so.
	ok( $master->send('shutdown'), '->send(shutdown) ok' );
	diag("Pausing to allow clean thread shutdown...");
	sleep 1;
	ok( ! $master->is_running,  'Master is not is_running' );
	ok(   $master->is_joinable, 'Master is_joinable' );
	ok( ! $master->is_detached, 'Master is not is_detached' );

	# Clean up and confirm it worked
	$master->join;
	is( scalar(threads->list), 0, 'Thread is gone' );
}





######################################################################
# Single Worker Start and Stop

SCOPE: {
	# Create the master thread
	my $master = Padre::Task2Master->new->spawn;
	isa_ok( $master, 'Padre::Task2Master' );
	is( scalar(threads->list), 1, 'Found 1 thread' );
	ok( $master->is_running, 'Master is_running' );

	# Create a single worker
	my $worker = Padre::Task2Worker->new( wid => 2 );
	isa_ok( $worker, 'Padre::Task2Worker' );

	# Start the worker inside the master
	ok( $master->add( $worker ), '->add ok' );
	diag("Pausing to allow worker thread startup...");
	sleep 1;
	is( scalar(threads->list), 2, 'Found 2 threads' );
	ok(   $master->is_running,  'Master is_running' );
	ok( ! $master->is_joinable, 'Master is not is_joinable' );
	ok( ! $master->is_detached, 'Master is not is_detached' );
	ok(   $worker->is_running,  'Worker is_running' );
	ok( ! $worker->is_joinable, 'Worker is not is_joinable' );
	ok( ! $worker->is_detached, 'Worker is not is_detached' );

}
