#!/usr/bin/perl

# Test the menu structure of Perl::Critic

use strict;
use warnings;

use Test::More tests => 3;
use Padre::Plugin::PerlCritic;

my @menu = Padre::Plugin::PerlCritic->menu_plugins_simple;
is( @menu, 2, 'Found one menu item' );
is( $menu[0], 'PerlCritic', 'Plugin name' );
is( $menu[1]->[0], 'Run PerlCritic', 'Menu item 1, Run PerlCritic' );
