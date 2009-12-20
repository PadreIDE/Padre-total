use strict;
use warnings;

$| = 1;
use File::Basename qw(basename);

my $file = basename($0);
print "$file\n";
