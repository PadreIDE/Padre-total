#!/usr/bin/perl

use strict;
use warnings;
use Test::More tests =>5;

use_ok('Padre::Plugin::Swarm');
use_ok('Padre::Swarm::Identity');
use_ok('Padre::Swarm::Message');
use_ok('Padre::Swarm::Message::Diff');

use_ok('Padre::Swarm::Service' );
