#!/usr/bin/perl
$|=1;

use strict;
use warnings;

print "\nPadre test script as preparation for auto-update\n\n".
      "This script will not do any updates itself, just do some OS tests which don't harm.\n\n";

$SIG{CHLD} = sub { wait; };

my $PID = fork; # Create a process for testing
if ( ! $PID) {
 sleep 1;
 exit;
}

print "My PID id $$, my child id $PID\n\n";

print "Running on $^O\n".
      "Child should be there... ";
if (kill(0,$PID)) {
 print "it is\n";
} else {
 print "no\n";
 die 'Unable to find child at first attempt';
}

print "Child should still be there... ";
if (kill(0,$PID)) {
 print "it is\n";
} else {
 print "no\n";
 die 'kill0 seems to kill child - bad';
}

sleep 2;
print "Child should be gone... ";
if ( ! kill(0,$PID)) {
 print "it is\n";
} else {
 print "no\n";
 die 'Child seems to be off but detection failed';
}

print "\nTest succeded!\n";
