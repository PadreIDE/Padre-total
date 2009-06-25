#!/usr/bin/perl
use strict;
use warnings;

# Experimental code to build a portable Perl for linux
# with Padre in it.

$ENV{PERL6LIB} = $ENV{PERL5LIB} = $ENV{PERLLIB} = '';

use FindBin;
use lib "$FindBin::Bin/../lib";
use Perl::Dist::XL;
use Getopt::Long qw(GetOptions);
my %conf;
GetOptions(\%conf, 
	"temp=s",
	"release=s",
	"skipperl",
	) or usage();
usage("need --release VERSION") if not $conf{release};

my $p = Perl::Dist::XL->new(%conf);
$p->build;

sub usage {
	my $str = shift;
	if ($str) {
		print "\n$str\n\n";
	}
	print <<"END_USAGE";
Usage: $0 --release VERSION    ( e.g. 0.01 )

       --temp  PATH/TO/TEMP/DIR
       --skipperl       to skip getting and building perl

END_USAGE
	exit;
}

