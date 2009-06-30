#!/usr/bin/perl

use strict;
use warnings;
use Test::More tests => 4;

use_ok('Padre::Plugin::Swarm');
use_ok('Padre::Task::Buzz');
use_ok('Padre::Swarm::Transport::Multicast');
use_ok('Padre::Swarm::Service::Chat' );
