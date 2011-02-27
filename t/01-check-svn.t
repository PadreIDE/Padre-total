#!/usr/env/perl

use strict;
use Padre::Plugin::SVN::Commands;

use Test::More;

plan tests => 1;

# want to test that svn is installed

my $svn_cmd = Padre::Plugin::SVN::Commands->new();

ok( ! $svn_cmd->error, "SVN not installed." );
