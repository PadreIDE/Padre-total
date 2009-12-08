#!/usr/bin/perl
use strict;
use warnings;

# Experimental code to build a portable Perl for linux
# with Padre in it.

$ENV{PERL6LIB} = $ENV{PERL5LIB} = $ENV{PERLLIB} = '';

use Data::Dumper qw(Dumper);
use FindBin;
use Getopt::Long qw(GetOptions);

use lib "$FindBin::Bin/../lib";
use Perl::Dist::XL;

usage() if not @ARGV;
my %conf;
GetOptions(\%conf, 
	'clean',
	'dir=s',
	'download',
	'help',
	'build=s@',
	'zip',
	'devperl',
	) or usage();
usage() if $conf{help};
#usage("need --download or --clean")
#	if not $conf{download} 
#	and not $conf{clean}
#	and not $conf{build}
#	and not $conf{zip};
#die Dumper \%conf;

my $p = Perl::Dist::XL->new(%conf);
$p->run;
exit;

sub usage {
	my $str = shift;
	if ($str) {
		print "\n$str\n\n";
	}
	print <<"END_USAGE";
Usage: $0

       --download      will dowsnload perl, CPAN modules, ...
       --clean         removes build files
       --build [perl|cpan|wx|padre|all]   where 'all' indicated all the others as well
       --zip           create the zip file

       --devperl       given this flag we will use the latest development version of perl
                       without this flag the latest stable version. (5.11.2 vs 5.10.1)

       --dir           PATH/TO/DIR (defaults to ~/.perldist_xl)

       --help          This help

END_USAGE
	exit;
}

