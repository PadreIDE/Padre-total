#!/usr/bin/perl 
use strict;
use warnings;


use Getopt::Long qw(GetOptions);
use File::Temp   qw(tempdir);
use Cwd          qw(cwd);

my $rev;
my $regex;
my $url;
my $first;
my $last;
my $path;
GetOptions(
	'revision=s' => \$rev,
	'url=s'      => \$url,
	'path=s'     => \$path,
	'first'      => \$first,
	'last'       => \$last,
	'regex=s'    => \$regex,
) or usage();
usage("Missing --revision REV") if not $rev;
usage("Either --firs or --last must be given") if not ($first xor $last);
usage("Either --url URL or --path PATH must be given") if not ($path xor $url);
usage("--regex REGEX  was missing") if not $regex;


if (not $url) {
	$url = get_url_from_local($path);
}

my ($first_rev, $last_rev) = split /:/, $rev;
if (not $last_rev) {
	my $head = get_head_rev($url);
	#print "HEAD: $head\n";
	$last_rev = $head;
}
print "Range $first_rev - $last_rev\n";

my $dir = tempdir (CLEANUP => 1);
my $cwd = cwd();
END {
	chdir $cwd;
}
chdir $dir;

my $cmd = "svn co -r$last_rev $url .";
print "$cmd\n";
qx{$cmd};

# BUG: might not work well if the string has appeared and 
# disappeared and appeared again.


if ($last) {
	#Check the last_rev, if it is there report
	#Check the diff between the first_rev and the last_rev to see if it was changed, 
	#       if not, report that it was not in that range 
	# 	TODO: and offer to expand search to older revisions (or do it automatically ?)
	# Then do a binary search for the last occurance
	if (in_rev($last_rev)) {
		print "Found in last rev ($last_rev)\n";
		exit;
	}
	if (not in_rev($first_rev)) {
		die "Not found in first rev ($rev)\n";
	}
	loop();
} elsif ($first) {
	# Check last_rev, if the string is not there, report that and quit
	# Check the first_rev if the string is there tell, report that the start is not in the range
	# Do a binary search
	if (not in_rev($last_rev)) {
		die "Not in last_rev ($last_rev)\n";
	}
	if (in_rev($first_rev)) {
		die "The string was in first_rev ($first_rev) already\n";
	}
	loop();
}

sub loop {
	while ($first_rev < $last_rev) {
		my $middle = int( ($last_rev+$first_rev) / 2 );
		print "Trying $first_rev - $middle - $last_rev\n";
		if ($last) {
			if (in_rev($middle)) {
				last if $middle == $first_rev;
				$first_rev = $middle;
			} else {
				$last_rev = $middle;
			}
		} else {
			if (in_rev($middle)) {
				$last_rev = $middle;
			} else {
				last if $middle == $first_rev;
				$first_rev = $middle;
			}
		}
	}
	print "Stopped at $first_rev - $last_rev\n";
	exit;
}


sub in_rev {
	my $rev = shift;
	
	my $cmd = "svn up -r$rev";
	print "$cmd\n";
	qx{$cmd};
	my $ack_cmd = qq(ack "$regex");
	print "$ack_cmd\n";
	return qx{$ack_cmd};
}


sub get_head_rev {
	my $url = shift;

	my @data = qx{svn info $url};
	chomp @data;
	my ($rev) = grep {/^Revision: \d+/} @data;
	if ($rev =~ /^Revision: (\d+)/) {
		return $1;
	}
	die "Could not determine head revision\n";
}

sub get_url_from_local {
	my $path = shift;
	my @data = qx{svn info $path};
	die "svn info failed\n" if not @data;
	my ($url) = grep {/^URL:/} @data;
	if ($url =~ /^URL:\s*(.*)/) {
		return $1;
	}
	die "Could not determined URL\n";
}

sub usage {
	my $msg = shift;
	if ($msg) {
		print "\n****: $msg\n";
	}
	print <<"END_USAGE";

Using binary search locate a revision in an SVN repository with the 
first (or last) apperance of a certain string.
	
Usage: $0
        Required:
        --revision FIRST_REV    or   FIRST_REV:LAST_REV
        --regex REGEX

        Exactly One of these:
        --first
        --last

        Exactly one of these:
        --url URL
        --path LOCAL_PATH
END_USAGE

	exit;
}


