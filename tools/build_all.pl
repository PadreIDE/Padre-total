#!/usr/bin/perl 
use strict;
use warnings;

# Try to run perl Makefile.PL or perl Build.PL on all the modules in this repository

use FindBin;
use Data::Dumper   qw(Dumper);
use File::Basename qw(basename);
use Capture::Tiny  qw(tee);

my %SKIP = map {$_ =>1 } qw(
	blogs.padre.perlide.org
);

my @dirs = grep { -d $_ } glob "$FindBin::Bin/../*";
#print Dumper \@dirs;

foreach my $dir (sort @dirs) {
	my $base = basename $dir;
	next if $SKIP{$base};

	chdir $dir;
	print "Trying $dir\n";
	unlink "Build", 'Makefile';
	if (-e 'Build.PL') {
		my ($stdout, $stderr) = tee {
			system "perl Build.PL" and die "$!";
		};
		die "There was an error (on stderr) in $base\n" if $stderr;
		die "Build was not created in $base\n" if not -e 'Build';
	} elsif (-e 'Makefile.PL') {
		my ($stdout, $stderr) = tee {
			system "perl Makefile.PL" and die "$!";
		};
		die "There was an error (on stderr) in $base\n" if $stderr;
		die "Makefile was not created in $base\n" if not -e 'Makefile';
	} else {
		die "No Build.PL, no Makefile.PL in $base\n";
	}
}
print "All done\n";