#
# This script is executed for every colorize event and is an attempt at 
# solving ticket:194 and preventing future dependency of on STD
#
use strict;
use warnings;

# parse arguments
my $num_args = $#ARGV + 1;
my $REQ_ARG_COUNT = 3;
if($num_args < $REQ_ARG_COUNT) {
    die "Error: p6tokens.pl needs $REQ_ARG_COUNT argument(s) (got $num_args).\n";
}

# read command-line arguments
my ($in_filename,$out_filename,$err_filename) = ($ARGV[0],$ARGV[1],$ARGV[2]);

# Redirect STDOUT/ERR to temporary filename.s..
open STDOUT, ">$out_filename"
	or die "Could not open $out_filename for writing (STDOUT)\n";
open STDERR, ">$err_filename"
	or die "Could not open $err_filename for writing (STDERR)\n";

my $text;
{
	# slurp the input file
	# Load file into a scalar without File::Slurp (see perlfaq5)
	open IN, $in_filename or die "Could not open $in_filename for reading (STDIN)\n";
	binmode IN;
	local $/ = undef;   #enable localized slurp mode
	$text = <IN>;
	close IN or die "Could not close $in_filename";
}

# create a syntax highlighter and serialize its tokens to STDOUT
require STD;
require Syntax::Highlight::Perl6;
my $p = Syntax::Highlight::Perl6->new(
    text => $text,
);
my @tokens = $p->tokens;
require Storable;
my $output = Storable::nfreeze(\@tokens);
binmode STDOUT;
print $output;

0;
