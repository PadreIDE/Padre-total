#!/usr/bin/env perl

use 5.010;
use strict;
use warnings;

# Turn on $OUTPUT_AUTOFLUSH
$| = 1;
# use diagnostics;
# use Data::Printer { caller_info => 1, colored => 1, };

say 'START';
use strict;
foreach (0..7)
{
 my $line = $_;
 last unless defined $line;		# exit loop if $line is not defined
 print "$_ : $line \n";
}


say 'END';
1;

__END__
