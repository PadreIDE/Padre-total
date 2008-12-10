#!/usr/bin/perl
use strict;
use warnings;

# update messages.pot file with new strings detected.
#
use Cwd                   qw{ cwd };
use File::Spec::Functions qw{ catfile catdir };
use File::Find::Rule;

my $cwd       = cwd;
my $localedir = catdir ( $cwd, 'share', 'locale' );
my $pot_file  = catfile( $localedir, 'messages.pot' );
my $pmfiles   = catfile( $cwd, 'files.txt' );

# build list of perl modules from where to extract strings
my @pmfiles = File::Find::Rule->file()->name("*.pm")->in("$cwd/lib");
open my $fh, '>', $pmfiles or die "cannot open '$pmfiles': $!\n";
print $fh map { "$_$/" } @pmfiles;
close $fh;

unlink $pot_file;
system("xgettext -o $pot_file -f $pmfiles") == 0
	or die "xgettext exited with return code " . $? >> 8;

# cleanup
unlink $pmfiles;
