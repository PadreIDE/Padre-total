#!/usr/bin/perl

use strict;
use warnings;
use Test::More;


BEGIN {
        unless ( $ENV{DISPLAY} or $^O eq 'MSWin32' ) {
                plan skip_all => 'Needs DISPLAY';
                exit 0;
        }
}

plan tests => 4;

use_ok('Padre::Plugin::Swarm');
use_ok('Padre::Swarm::Identity');
use_ok('Padre::Swarm::Message');
use_ok('Padre::Swarm::Message::Diff');

