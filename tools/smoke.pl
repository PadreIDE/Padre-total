#!/usr/bin/perl
use strict;
use warnings;

# first attempt to build a smoke client for padre
# install TAP::Harness::Archive

# manually check out the svn repository of Padre
# in the Padre/ dir create file called smoke.conf with
#   username
#   password
# in it your user on http://smolder.plusthree.com/
# which needs to be associated with the Padre project
# then you can run this script with --path pointing to the Padre directory

use Getopt::Long qw(GetOptions);
my $path;
my $help;
GetOptions(
	'path=s' => \$path,
	'help'   => \$help,
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
my @status = `$SVN st -u`;
exit if @status <= 1;

system "$SVN up";
system "perl Makefile.PL";
# TODO - report if requirements changed and stop running
system "make";
my $file = 'tap.tar.gz';
unlink $file;
system "prove -ba $file t/ xt/";
system "smolder_smoke_signal --server smolder.plusthree.com --username $username --password $password --file $file --project Padre";


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

