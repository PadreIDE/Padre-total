#!/usr/bin/perl

# Start a worker thread from inside another thread

#BEGIN {
#$Padre::Task2Thread::DEBUG = 1;
#$Padre::Task2Worker::DEBUG = 1;
#}

use strict;
use warnings;
use Test::More tests => 5;
use Test::NoWarnings;
use Time::HiRes 'sleep';
use Padre::Logger;
use Padre::Task2Thread ':master';

# Do we start with one thread as expected
sleep 0.1;
is( scalar(threads->list), 1, 'One thread exists' );

# Fetch the master, is it the existing one?
my $master1 = Padre::Task2Thread->master;
my $master2 = Padre::Task2Thread->master;
isa_ok( $master1, 'Padre::Task2Thread' );
isa_ok( $master2, 'Padre::Task2Thread' );
is( $master1->wid, $master2->wid, 'Masters match' );
