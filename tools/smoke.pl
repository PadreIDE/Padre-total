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

use Getopt::Long qw(GetOptions);
my $path;
my $help;
my $sleep;
GetOptions(
	'path=s'  => \$path,
	'help'    => \$help,
	'sleep=s' => \$sleep,
) or usage();
usage() if $help;
usage('Needs --path') if not $path;

chdir $path;
open my $fh, '<', 'smoke.conf' or die;
my $username = <$fh>;
my $password = <$fh>;
chomp $username;
chomp $password;

my $SVN = 'svn';

while (1) {
	print "\n";
	print scalar localtime;

	my @diff = `$SVN diff -rHEAD`;
	
	if (@diff) {
		print " - running\n";
		#print "status @diff";

		system "$SVN up";
		system "perl Makefile.PL";
		# TODO - report if requirements changed and stop running
		system "make";
		my $file = 'tap.tar.gz';
		unlink $file;
		system "prove -ba $file t/ xt/";
		system "smolder_smoke_signal --server smolder.plusthree.com --username $username --password $password --file $file --project Padre";
	} else {
		print " - skipping\n";
	}
	last if not $sleep;
	sleep $sleep;
}

sub usage {
	my $msg = shift;
	if ($msg) {
		print "\nERROR: $msg\n\n";
	}
	print <<"END";

Usage: $0
       --path PATH/TO/SVN/DIR
       --help                    this help
END
	exit;
}

