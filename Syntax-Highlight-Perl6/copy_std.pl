#!/usr/bin/perl

#imports
use strict;
use warnings;
use feature 'say';
use Carp;
use Cwd;

# some constants
my $PUGS = '../../pugs';
my $STD = "$PUGS/src/perl6";
my $status;

# svn update to the latest
say "\n--Running 'svn update'";
$status = system("svn update $PUGS"); 
die "Could not svn update pugs\n" if $status != 0;

# make STD.pm6
my $make = $^O eq 'MSWin32' ? 'dmake.exe' : 'make';
say "\n--Running 'make clean all' for STD.pm6";
my $cwd = getcwd;
chdir $STD or die "Could not change dir to $STD\n";
$status = system("$make clean all"); 
die "Could not make STD.pm6\n" if $status != 0;

# copy STD.pm6 files
say "\n--Copying STD.pm6 files";
chdir $cwd or die "Could not change dir to $cwd\n";

# list of files to copy
my %files = (
    "*.pmc" => "lib",
    "Actions.pm" => "lib",
    "LazyMap.pm" => "lib",
    "mangle.pl"  => "lib",
    "uniprops"   => "lib",
    "syml/CORE.syml" => "lib/Syntax/Highlight/Perl6/syml",
);

# copy files
for my $file (keys %files) {
    my $dest = $files{$file};
    my $src = "$STD/$file";
    my $cmd = "perl -MExtUtils::Command -e cp $src $dest";
    say $cmd;
    my $status = system($cmd);
    die "Could not copy $src" if $status != 0;
}

say "\nThanks!\nPlease remember to '$make test' and then commit changed files if it works";
