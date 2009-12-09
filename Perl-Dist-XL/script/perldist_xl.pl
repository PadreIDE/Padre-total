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
	'perl=s',
	) or usage();
usage() if $conf{help};
usage('--perl is required') if not $conf{perl};
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

       --perl [dev|stable|git]      which version of perl to use
                       dev    = 5.11.2
                       stable = 5.10.1
                       git    = ????

       --dir           PATH/TO/DIR (defaults to ~/.perldist_xl)

       --help          This help

END_USAGE
	exit;
}

