#!/usr/bin/perl
use strict;
use warnings;

# include Parrot and Rakudo in the portable Strawberry release
use File::Basename qw(basename dirname);
use File::Spec;
use File::Path qw(mkpath);
use File::Copy qw(copy);

my $src  = "c:/gabor/parrot";
my $dest = "c:/portable/parrot";

foreach my $file (<DATA>) {
	print $file;
	chomp $file;
	next if not $file;
	my $path = dirname ($file);
	print "PATH: $path\n";
	my $dir = $path eq '.' ? $dest : File::Spec->catdir($dest, $path);
	mkpath $dir;
	copy(File::Spec->catfile($src, $file), File::Spec->catdir($dest, $path));
}

__END__
parrot.exe
libparrot.dll
languages/perl6/perl6.pbc
