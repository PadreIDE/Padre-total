#
# This script is executed for every colorize event and is an attempt at 
# solving ticket:194 and preventing future dependency of on STD
#
use strict;
use warnings;

# parse arguments
my $num_args = $#ARGV + 1;
if($num_args != 1) {
    die "p6tokens.pl needs one file.\n";
}

# Load file into a scalar without File::Slurp (see perlfaq5)
my $filename = $ARGV[0];
my $text;
{
	# slurp the input file
	open IN, $filename or die "Could not open $filename for reading";
	local $/ = undef;   #enable localized slurp mode
	$text = <IN>;
	close IN or die "Could not close $filename";
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
