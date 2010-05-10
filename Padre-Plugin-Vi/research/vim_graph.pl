#!/usr/bin/perl

use strict;
use warnings;
use 5.010;
use lib 'lib';
use Moose::Autobox;
use List::MoreUtils qw(zip);
use IO::All;
use Data::Dumper;
use aliased 'Vimper::CommandSheet';
use aliased 'Vimper::SyntaxDag';

# parse the normal motion file and create the graph of all
# possible syntax paths for all commands

my $normal_motion = CommandSheet->new(file => 'normal_motion.tsv');
my $syntax_dag = SyntaxDag->new(src => $normal_motion);
$syntax_dag->graph;

