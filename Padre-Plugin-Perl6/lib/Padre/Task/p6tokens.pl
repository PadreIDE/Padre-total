use strict;
use warnings;

use STD;
use Syntax::Highlight::Perl6;
use Storable qw( nfreeze );

#local $/ = undef;
my $text = <>;
while(<>) {
    $text .= $_;
}

use IO::File;
my $fh = IO::File->new('>p6tokens.txt');
print $fh "$text";
close $fh;

my $p = Syntax::Highlight::Perl6->new(
    text => $text,
);

my @tokens = $p->tokens;
my $output = nfreeze(\@tokens);
binmode(STDOUT);
print $output;

0;