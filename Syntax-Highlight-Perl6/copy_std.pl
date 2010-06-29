#!/usr/bin/perl

use strict;
use warnings;
use feature 'say';
use Carp;
use Cwd;

my $PUGS = '../../pugs';
my $STD = "$PUGS/src/perl6";
my $status;

say "\n--Running 'svn update'";
$status = system("svn update $PUGS"); 
die "Could not svn update pugs\n" if $status != 0;

my $make = $^O eq 'MSWin32' ? 'dmake.exe' : 'make';
say "\n--Running 'make clean all' for STD.pm6";
my $cwd = getcwd;
chdir $STD or die "Could not change dir to $STD\n";
$status = system("$make clean all dist"); 
die "Could not make STD.pm6\n" if $status != 0;

say 'Building and copying STD.pm6 files';
chdir $cwd or die "Could not change dir to $cwd\n";

$status = system("cp $STD/dist/lib/* lib");
die "Could not copy dist/lib" if $status != 0;

$status = system("cp $STD/dist/lib6/* lib");
die "Could not copy dist/lib" if $status != 0;

$status = system("cp $STD/dist/syml/* lib");
die "Could not copy dist/syml" if $status != 0;
