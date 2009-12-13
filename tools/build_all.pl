#!/usr/bin/perl 
use strict;
use warnings;

# Try to run perl Makefile.PL or perl Build.PL on all the modules in this repository
# later we might just run the release.pl script on each directory 
# (or that could be a second phase)

use FindBin;
use Data::Dumper   qw(Dumper);
use File::Basename qw(basename);
use Capture::Tiny  qw(tee);

my %SKIP = (
	'Acme-CPANAuthors-Padre'    => 'not a plugin',
	'Padre-Artwork'             => 'not code',
	'Padre-Plugin-Encode'       => 'due to be integrated',
	'Padre-Plugin-HTML'         => 'HTML::Tidy is a broken prereq',
	'Padre-Plugin-NYTProf'      => 'TODO',
	'Padre-Plugin-Alarm'        => 'broken translation files?',
	'Padre-Plugin-Perldoc'      => 'irrelevant, broken prereq',
	'Padre-Plugin-Swarm'        => 'just a skeleton',
	'Perl-Dist-Padre'           => 'needs Perl::Dist::Strawberry',
	'Task-Padre-Plugin-Deps'    => 'HTML::Tidy is broken',
	'Task-Padre-Plugins'        => '???',
	'Wx-Perl-Dialog'            => 'currently not in use',
);

my @dirs = grep { -d $_ } glob "$FindBin::Bin/../[A-Z]*";
#print Dumper \@dirs;

foreach my $dir (sort @dirs) {
	my $base = basename $dir;
	next if $SKIP{$base};

	chdir $dir;
	print "Trying $dir\n";
	unlink "Build", 'Makefile';
	if (-e 'Build.PL') {
		my ($stdout, $stderr) = tee {
			system "perl Build.PL" and die "($base failed:) $!";
		};
		die "There was an error (on stderr) in $base\n" if $stderr;
		die "Build was not created in $base\n" if not -e 'Build';
	} elsif (-e 'Makefile.PL') {
		my ($stdout, $stderr) = tee {
			system "perl Makefile.PL" and die "($base failed:) $!\n";
		};
		die "There was an error (on stderr) in $base\n" if $stderr;
		die "Makefile was not created in $base\n" if not -e 'Makefile';
	} else {
		die "No Build.PL, no Makefile.PL in $base\n";
	}
}
print "All done\n";
