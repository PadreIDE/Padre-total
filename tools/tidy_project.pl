#!/usr/bin/perl

use strict;
use warnings;

#
use Cwd                   qw{ cwd };
use File::Spec::Functions qw{ catfile catdir };
use File::Find::Rule;
use FindBin qw{ $Bin };

# check if perltidyrc file exists
my $perltidyrc = catfile( $Bin, 'perltidyrc' );
die "cannot find perltidy configuration file: $perltidyrc\n"
	unless -e $perltidyrc;

# build list of perl modules to reformat
my @pmfiles = @ARGV
	? @ARGV
	: grep {/^lib/}	File::Find::Rule->file->name("*.pm")->relative->in(cwd);
my @tfiles = @ARGV
	? @ARGV
	: grep {/^t/}	File::Find::Rule->file->name("*.t")->relative->in(cwd);

my @files = (@pmfiles,@tfiles);
push @files, 'Makefile.PL' if -f 'Makefile.PL';
push @files, 'Build.PL' if -f 'Build.PL';

# formatting documents
my $cmd = "perltidy --backup-and-modify-in-place --profile=$perltidyrc @files";
system($cmd) == 0 or die "perltidy exited with return code " . ($? >> 8);

# removing backup files
unlink map {"$_.bak"} @files;