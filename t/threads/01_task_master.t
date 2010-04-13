#!/usr/bin/perl

# Spawn and then shut down the task master object

use strict;
use warnings;
use Test::More tests => 17;
use Test::NoWarnings;
use Padre::Task2Master;

# Create the master thread
my $master = Padre::Task2Master->new;
isa_ok( $master, 'Padre::Task2Master' );
isa_ok( $master->queue, 'Thread::Queue' );
isa_ok( $master->thread, 'threads' );
my $tid = $master->thread->tid;
ok( $tid, "Got thread id $tid" );

# Does the threads module agree it was created
my @threads = threads->list;
is( scalar(@threads), 1, 'Found one thread' );
is( $threads[0]->tid, $tid, 'Found the expected thread id' );

# Initially, the thread should be running
ok( $master->thread->is_running, 'Thread is_running' );
ok( ! $master->thread->is_joinable, 'Thread is not is_joinable' );
ok( ! $master->thread->is_detached, 'Thread is not is_detached' );

# It should stay running
diag("Pausing to allow clean thread startup...");
sleep 1;
ok(   $master->thread->is_running,  'Thread is_running' );
ok( ! $master->thread->is_joinable, 'Thread is not is_joinable' );
ok( ! $master->thread->is_detached, 'Thread is not is_detached' );

# Instruct the master to shutdown, and give it a brief time to do so.
ok( $master->send('shutdown'), '->send(shutdown) ok' );
diag("Pausing to allow clean thread shutdown...");
sleep 1;
ok( ! $master->thread->is_running,  'Thread is not is_running' );
ok(   $master->thread->is_joinable, 'Thread is_joinable' );
ok( ! $master->thread->is_detached, 'Thread is not is_detached' );

