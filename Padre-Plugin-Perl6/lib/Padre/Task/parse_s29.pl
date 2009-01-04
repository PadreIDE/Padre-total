
use strict;
use warnings;
use feature qw(say);
use IO::File;
use Carp;

# open the S29 file
my $S29 = IO::File->new('S29-Functions.pod') 
    or croak "Cannot open $!";

# read until you find 'Function Packages'
until (<$S29> =~ /Function Packages/) {}

# parse all the all looking for function documentation
my %functions = ();
my $function_name = undef;
while (my $line = <$S29>) {
    if ($line =~ /^=(\S+) (.*)/x) {
        if ($1 eq 'item') {
            # Found Perl6 function name
            $function_name = $2;
            $function_name =~ s/^\s+//;
        } else {
            $function_name = undef;
        }
    } elsif($function_name) {
        # Adding documentation to the function name
        $functions{$function_name} .= $line;
    }
}
for my $func_name (keys %functions) {
    say $func_name . "\n" . $functions{$func_name};
}