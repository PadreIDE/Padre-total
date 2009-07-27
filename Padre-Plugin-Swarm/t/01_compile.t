#!/usr/bin/perl

use strict;
use warnings;
use Test::More tests => 7;

use_ok('Padre::Plugin::Swarm');
use_ok('Padre::Swarm::Identity');
use_ok('Padre::Swarm::Message');
use_ok('Padre::Swarm::Message::Diff');
use_ok('Padre::Swarm::Transport::Multicast');
use_ok('Padre::Swarm::Transport::IRC');

use_ok('Padre::Swarm::Service::Chat' );
