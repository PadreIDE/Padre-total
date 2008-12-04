#!/usr/bin/perl

use strict;
use warnings;
use Test::More;
use Data::Dumper;
use vars qw/@windows/;

BEGIN {
    eval 'use Win32::GuiTest qw(:ALL);'; ## no critic (ProhibitStringyEval)
    $@ and plan skip_all => 'Win32::GuiTest is required for this test';
    
    @windows = FindWindowLike(0, "^Padre");
    scalar @windows or plan skip_all => 'You need open Padre then start this test';
};

plan tests => 1;

my $padre = $windows[0];

my $menu = GetMenu($padre);

# test File
my $submenu = GetSubMenu($menu, 0);
my %h = GetMenuItemInfo($menu, 0);
is $h{text}, '&File';

# test Edit
my $submenu = GetSubMenu($menu, 1);
my %h = GetMenuItemInfo($menu, 1);
is $h{text}, '&Edit';

1;