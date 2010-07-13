#!/usr/bin/perl
use strict;
use warnings;

# first attempt to build a smoke client for padre
# install WWW::Mechanize and TAP::Harness::Archive, 
# install MIME::Lite
# fetch the smolder_smoke_signal script from the Smolder package
# and put it in the PATH
# TODO: check out App-Smolder-Report or Create Smolder::Client
# TODO: include the plugins as well in the smoking

# these two are actually needed externally but we load
# them here now to make sure the user does not forget to install them
use TAP::Harness::Archive;
use WWW::Mechanize;

use Capture::Tiny qw(capture_merged);
use Data::Dumper qw(Dumper);
use Getopt::Long  qw(GetOptions);
use MIME::Lite;
my $path;
my $help;
my $sleep;
my $force;
my $verbose;
my $to;
my $smolder;
GetOptions(
	 'path=s'    => \$path,
	 'to=s'      => \$to,
	 'help'      => \$help,
	 'sleep=s'   => \$sleep,
	 'force'     => \$force,
	 'verbose'   => \$verbose,
	 'smolder=s' => \$smolder,
) or usage();
usage() if $help;
usage('Needs --path')    if not $path;
usage('Needs --to')      if not $to;
usage('Needs --smolder') if not $smolder;

my %MAIL = (
	adamk   => 'adamk@perlide.org',
	Sewi    => 'sewi@perlide.org',
	waxhead => 'waxhead@perlide.org',
#	adamk   => 'adamk@cpan.org',
#	Sewi    => 's.willing@tsbz.de',
#	waxhead => 'plaven@bigpond.net.au',
);

$ENV{AUTOMATED_TESTING} = 1;
$ENV{RELEASE_TESTING}   = 1;

chdir $path;
open my $fh, '<', 'smoke.conf' or usage("Need to have a smoke.conf");
my $username = <$fh>;
my $password = <$fh>;
chomp $username;
chomp $password;

my $SVN  = 'svn';
my $MAKE = $^O =~ /Win32/i ? 'dmake' : 'make';
my $platform = $^O;

my $output;
while (1) {
	print "\n";
	print scalar localtime;
	$output = '';

	my ($old_rev, $old_author) = svn_revision();
	my @diff = qx{$SVN diff -rHEAD};
	my $status = '';
	
	if (@diff or $force) {
		print " - running\n";
		#print "status @diff";

		system "$MAKE realclean";
		_system("$SVN up");

		my ($rev, $author) = svn_revision();
		if ($rev == $old_rev and not $force) {
			$output .= "\n\nSome serious trouble as we could not update from SVN (rev $rev)\n";
			$status = "FAIL - could not update svn";
			next; # Let's not send an e-mail now
		}
		if (not $status) {
			my $make_out = _system("$^X Makefile.PL");
			if ($make_out =~ /Warning: prerequisite (.*)/) {
				$output = "\n\nThere seem to be at least one missing prerequisite:\n$1";
				$output .= "\n\nThere might be more missing\n";
				$status = "FAIL - missing prereq";
				# TODO, list al the missing prereqs
			}
		}
		if (not $status) {
			_system($MAKE);
		}
		if (not $status) {
			my $file = 'tap.tar.gz';
			unlink $file;
			my $test_out = _system("prove --merge -ba $file t/ xt/");
			#my $test_out = "FAIL"; 
			if ($test_out =~ /Result: FAIL|FAILED|Bailout called/) {
				$status = "FAIL - testing";
			}
			_system("$^X $smolder --server smolder.plusthree.com --username $username --password $password --file $file --project Padre --revision $rev --platform $platform");
			$output .= "\nReports are at http://smolder.plusthree.com/app/public_projects/smoke_reports/11\n";
		}

		$status ||= "SUCCESS";
		send_message($rev, $author, "rev $rev - $platform - $status", $output);
	} else {
		print " - skipping\n";
	}
} continue {
	last if not $sleep;
	sleep $sleep;
	$force = 0;
}

sub svn_revision { 
	#my ($rev) = map {/(\d+)/} grep {/^Last Changed Rev:/} qx{$SVN info};
	my @info = qx{$SVN info};
	my ($rev) = map {/(\d+)/} grep {/^Revision:/} @info;
	my ($author) = map {/:\s*(\w+)/} grep {/^Last Changed Author:/} @info;
	return ($rev, $author);
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
	my ($rev, $author, $status, $text) = @_;
	my %message = (
		From     => "$username <svn\@perlide.org>",
		To       => $to,
		Subject  => "Padre Smoke test $status",
		Type     => 'multipart/mixed',
	);
	if ($MAIL{$author}) {
		$message{CC} = $MAIL{$author}
	}
	#print Dumper \%message;

	my $msg = MIME::Lite->new(%message);
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
       --smolder PATH            path to the smolder_smoke_signal script

Setup:
  Install command line Subversion client.
  (For windows download it from http://www.collab.net/downloads/subversion/
   where free registration required)
  
  Manually check out the svn repository of Padre:
  svn co  http://svn.perlide.org/padre/trunk/Padre

  In the new Padre/ directory create file called smoke.conf with
    your username and password on http://smolder.plusthree.com/ in the file
  Make sure they are associated with the Padre project on that smolder installation
   username
   password

  Make sure all the prereqisites are installed

  Then you can run this script with --path pointing to the Padre directory, 
  --to being your e-mail 
  provide --sleep 60 if you would like to have the script executed every 60 second

END
	exit;
}

