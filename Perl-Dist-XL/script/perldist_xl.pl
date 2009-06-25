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
	) or die;
die "need --release VERSION\n" if not $conf{release};

my $p = Perl::Dist::XL->new(%conf);
$p->build;


