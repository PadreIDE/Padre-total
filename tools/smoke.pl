#!/usr/bin/perl
use strict;
use warnings;

# first attempt to build a smoke client for padre
# install WWW::Mechanize and TAP::Harness::Archive, 
# fetch the smolder_smoke_signal script from the Smolder package
# and put it in the PATH
# TODO: check out App-Smolder-Report 

# manually check out the svn repository of Padre:
#   svn co  http://svn.perlide.org/padre/trunk/Padre

# in the new Padre/ directory create file called smoke.conf with
# put your username and passoworf on http://smolder.plusthree.com/ in the file
# and make sure they are associated with the Padre project on that smolder installation
#   username
#   password

# make sure all the prereqisites are installed

# then you can run this script with --path pointing to the Padre directory
# provide --sleep 60 if you would like to have the script executed every 60 second

use Capture::Tiny qw(capture_merged);
use Getopt::Long  qw(GetOptions);
use MIME::Lite;
my $path;
my $help;
my $sleep;
my $force;
my $verbose;
my $to;
GetOptions(
	'path=s'  => \$path,
	'to=s'    => \$to,
	'help'    => \$help,
	'sleep=s' => \$sleep,
	'force'   => \$force,
	'verbose' => \$verbose,
) or usage();
usage() if $help;
usage('Needs --path') if not $path;
usage('Needs --to')   if not $to;

chdir $path;
open my $fh, '<', 'smoke.conf' or die;
my $username = <$fh>;
my $password = <$fh>;
chomp $username;
chomp $password;

my $SVN = 'svn';

my $output;
while (1) {
	print "\n";
	print scalar localtime;
	$output = '';

	my $old_rev = svn_revision();
	my @diff = qx{$SVN diff -rHEAD};
	my $status = '';
	
	if (@diff or $force) {
		print " - running\n";
		#print "status @diff";

		_system("$SVN up");
		my $rev = svn_revision();
		if ($rev == $old_rev and not $force) {
			$output .= "\n\nSome serious trouble as we could not update from SVN (rev $rev)\n";
			$status = "MAJOR FAIL at r$rev - could not update svn";
		}
		if (not $status) {
			my $make_out = _system("$^X Makefile.PL");
			if ($make_out =~ /Warning: prerequisite (.*)/) {
				$output = "\n\nThere seem to be at least one missing prerequisite:\n$1";
				$status = "MAJOR FAIL at r$rev - missing prereq";
			}
		}
		if (not $status) {
			_system("make");
		}
		if (not $status) {
			my $file = 'tap.tar.gz';
			unlink $file;
			my $test_out = _system("prove --merge -ba $file t/ xt/");
			if ($test_out =~ /Result: FAIL/) {
				$status = "FAIL at r$rev - testing";
			}
			_system("smolder_smoke_signal --server smolder.plusthree.com --username $username --password $password --file $file --project Padre --revision $rev");
			$output .= "\nReports are at http://smolder.plusthree.com/app/public_projects/smoke_reports/11\n";
		}

		$status ||= "SUCCESS at r$rev";
		send_message($rev, $status, $output);
	} else {
		print " - skipping\n";
	}
	last if not $sleep;
	sleep $sleep;
	$force = 0;
}

sub svn_revision { 
	#my ($rev) = map {/(\d+)/} grep {/^Last Changed Rev:/} qx{$SVN info};
	my ($rev) = map {/(\d+)/} grep {/^Revision:/} qx{$SVN info};
	return $rev;
};
sub _system {
	my $cmd = shift;

	# Let's not send out the password of the smoke server to the mailing list
	if ($cmd !~ /--password/) {
		$output .= "\n\n$cmd\n\n";
	}
	print "$cmd\n" if $verbose;
	my $out = capture_merged { system $cmd; };
	#print $out if $verbose;
	$output .= $out;
	return $out;
}

sub send_message {
	my ($rev, $status, $text) = @_;
	my $msg = MIME::Lite->new(
		From     => 'svn@perlide.org',
		To       => $to,
		Subject  => "Smoke test $status",
		Type     => 'multipart/mixed',
	);
	$msg->attach(
		Type     => 'TEXT',
		Data     => $text,
	);

	$msg->send('smtp','mail.perlide.org', Debug => 0 );
}


sub usage {
	my $msg = shift;
	if ($msg) {
		print "\nERROR: $msg\n\n";
	}
	print <<"END";

Usage: $0
       --path PATH/TO/SVN/DIR
       --to EMAIL                where to send the report (e.g. gabor\@perl.org.il or padre-commit\@perlide.org)
       --help                    this help
       --sleep N                 after each run sleep N and then rerun (without this runs only once)
       --force                   force a build and report even if there were no changes (for the first run only)
       --verbose                 print output to screen
END
	exit;
}

