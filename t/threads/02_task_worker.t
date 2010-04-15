#!/usr/bin/perl

# Spawn and then shut down the task worker object.
# Done in similar style to the task master to help encourage
# implementation similarity in the future.

use strict;
use warnings;
use Test::More tests => 19;
use Test::NoWarnings;
use Padre::Task2Worker;

# Create the master thread
my $worker = Padre::Task2Worker->new( wid => 2 )->spawn;
isa_ok( $worker, 'Padre::Task2Worker' );
is( $worker->wid, 2, '->wid ok' );
isa_ok( $worker->queue, 'Thread::Queue' );
isa_ok( $worker->thread, 'threads' );
ok( ! $worker->is_thread, '->is_thread is false' );
my $tid = $worker->thread->tid;
ok( $tid, "Got thread id $tid" );

# Does the threads module agree it was created
my @threads = threads->list;
is( scalar(@threads), 1, 'Found one thread' );
is( $threads[0]->tid, $tid, 'Found the expected thread id' );

# Initially, the thread should be running
ok( $worker->is_running, 'Thread is_running' );
ok( ! $worker->is_joinable, 'Thread is not is_joinable' );
ok( ! $worker->is_detached, 'Thread is not is_detached' );

# It should stay running
diag("Pausing to allow clean thread startup...");
sleep 1;
ok(   $worker->is_running,  'Thread is_running' );
ok( ! $worker->is_joinable, 'Thread is not is_joinable' );
ok( ! $worker->is_detached, 'Thread is not is_detached' );

# Instruct the master to shutdown, and give it a brief time to do so.
ok( $worker->send('shutdown'), '->send(shutdown) ok' );
diag("Pausing to allow clean thread shutdown...");
sleep 1;
ok( ! $worker->is_running,  'Thread is not is_running' );
ok(   $worker->is_joinable, 'Thread is_joinable' );
ok( ! $worker->is_detached, 'Thread is not is_detached' );
