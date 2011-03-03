#!/usr/bin/env perl

use strict;
use warnings;

eval("require Perl::Tidy");
if ($@) {
	die "Please install Perl::Tidy (e.g. cpan Perl::Tidy)";
}

my $ver = '20101217';
if ( $Perl::Tidy::VERSION ne $ver ) {
	die "Please install version $ver of Perl::Tidy";

	# Make sure everyone uses the exact same version!
}


#
use Cwd qw{ cwd };
use File::Spec::Functions qw{ catfile catdir };
use File::Find::Rule;
use FindBin qw{ $Bin };

# check if perltidyrc file exists
my $perltidyrc = catfile( $Bin, 'perltidyrc' );
die "cannot find perltidy configuration file: $perltidyrc\n"
	unless -e $perltidyrc;

# build list of perl files to reformat
my @pmfiles =
	  @ARGV
	? @ARGV
	: grep {/^lib/} File::Find::Rule->file->name("*.pm")->relative->in(cwd);
my @tfiles =
	  @ARGV
	? @ARGV
	: grep {/^x?t/} File::Find::Rule->file->name("*.t")->relative->in(cwd);
my @examples =
	  @ARGV
	? @ARGV
	: grep {/^share.examples/} File::Find::Rule->file->name("*.pl")->relative->in(cwd);

my @files = ( @pmfiles, @tfiles, @examples );

my @extras = ( 'Makefile.PL', 'Build.PL', 'dev.pl', 'script/padre', );
for my $extra (@extras) {
	push @files, $extra if -f $extra;
}

# formatting documents
eval { Perl::Tidy::perltidy( argv => "--backup-and-modify-in-place --profile=$perltidyrc @files" ); };
if ($@) {
	print "Perl::Tidy failed with the following error:\n$@\n";
}

# removing backup files
unlink map {"$_.bak"} @files;
