#!perluse strict;use warnings;
$| = 1;
print "What is your name ?";my $name = <STDIN>;chomp $name;print "Hello $name!\n";
