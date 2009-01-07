#
# This script is executed for every colorize event and is an attempt at 
# solving ticket:194 and preventing future dependency of on STD
#
use strict;
use warnings;

use STD;
use Syntax::Highlight::Perl6;
use Storable qw( nfreeze );

# read input from STDIN
my $text = '';
my $line;
binmode STDIN;
while($line = <STDIN>) {
    $text .= $line;
}

# create a syntax highlighter and serialize its tokens to STDOUT
my $p = Syntax::Highlight::Perl6->new(
    text => $text,
);
my @tokens = $p->tokens;
my $output = nfreeze(\@tokens);
binmode STDOUT;
print $output;

0;
