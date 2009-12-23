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
	'build=s',
	'module=s',
	'zip',
	'perl=s',
	'full',
	'verbose',
	) or usage();
usage() if $conf{help};
usage('--perl is required') if not $conf{perl} or ($conf{perl} ne 'stable' and $conf{perl} ne 'dev');
usage("need one of theses: --download, --clean, --build, --module or --zip")
	if  not $conf{download} 
	and not $conf{clean}
	and not $conf{build}
	and not $conf{module}
	and not $conf{zip};
#die Dumper \%conf;

my $p = Perl::Dist::XL->new(%conf);
$p->run;
exit;

sub usage {
	my $str = shift;
	if ($str) {
		print "\n$str\n\n";
	}

	my $perl_dev  = Perl::Dist::XL::perl_dev();
	my $perl_prod = Perl::Dist::XL::perl_prod();
	my $steps     = join '|', Perl::Dist::XL::get_steps();
	print <<"END_USAGE";
Usage: $0


       --download      will dowsnload perl, CPAN modules, ...
       --clean         removes build files
       --build [$steps|all]   where 'all' indicated all the others as well
       --module Module::Name
       --verbose              display all the output
       --zip           create the zip file

  Alternative:
       --download --full       full Mini CPAN mirror

       --perl [dev|stable|git]      which version of perl to use
                       dev    = $perl_dev
                       stable = $perl_prod
                       git    = ????

       --dir           PATH/TO/DIR (defaults to ~/.perldist_xl)


       --help          This help

END_USAGE
	exit;
}

