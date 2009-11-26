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

my %conf;
GetOptions(\%conf, 
	'clean',
	'dir=s',
	'download',
	'help',
	'build=s@',
	) or usage();
usage() if $conf{help};
usage("need --download or --clean")
	if not $conf{download} 
	and not $conf{clean}
	and not $conf{build};
#usage("need --release VERSION") if not $conf{release};
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
       --build [perl|all]

       --dir           PATH/TO/DIR (defaults to ~/.perldist_xl)

       --help          This help

END_USAGE
	exit;
}

