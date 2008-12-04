#!/usr/bin/perl

use strict;
use warnings;
use Test::More;
use FindBin qw/$RealBin/;
use vars qw/@windows/;

BEGIN {
    eval 'use Win32::GuiTest qw(:ALL);'; ## no critic (ProhibitStringyEval)
    $@ and plan skip_all => 'Win32::GuiTest is required for this test';
    
    @windows = FindWindowLike(0, "^Padre");
    scalar @windows or plan skip_all => 'You need open Padre then start this test';
};

plan tests => 2;

my $padre = $windows[0];
SetForegroundWindow($padre);

MenuSelect("&File|&New");
sleep 1;

Win32::GuiTest::SendKeys("If you're reading this inside Padre, ");
Win32::GuiTest::SendKeys("we might consider this test succesful. ");
Win32::GuiTest::SendKeys("Please wait.......");

# get old $default_dir
my $old_default_dir = $Padre::Wx::MainWindow::default_dir;
$Padre::Wx::MainWindow::default_dir = $RealBin;

MenuSelect("&File|&Save");

my $save_to = "$$.txt";
unlink("$RealBin/$save_to");

SendKeys($save_to);
SendKeys("%{S}");

# check the file
ok(-e "$RealBin/$save_to", 'file saved');

open(my $fh, '<', "$RealBin/$save_to");
local $/;
my $text = <$fh>;
close($fh);
like($text, qr/inside Padre/);

# restore
MenuSelect("&File|&Close");
unlink("$RealBin/$save_to");
$Padre::Wx::MainWindow::default_dir = $old_default_dir;

1;