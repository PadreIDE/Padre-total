#!/usr/bin/perl

use strict;
use warnings;

use FindBin      qw($Bin);
use File::Spec   ();
use File::Temp   ();
use Data::Dumper qw(Dumper);

use Test::More tests => 2;

use Padre::Autosave;

my $dir = File::Temp::tempdir( CLEANUP => 1);

my $db_file = File::Spec->catfile($dir, 'backup.db');
my $autosave = Padre::Autosave->new(dbfile => $db_file);

isa_ok($autosave, 'Padre::Autosave');
ok(-e $db_file, 'database file created');


