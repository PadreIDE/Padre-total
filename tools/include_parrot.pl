#!/usr/bin/perl
use strict;
use warnings;

# include Parrot and Rakudo in the portable Strawberry release
use File::Basename qw(basename dirname);
use File::Spec;
use File::Path qw(mkpath);
use File::Copy qw(copy);

#my $src  = "c:/gabor/parrot";
#my $dest = "c:/portable/parrot";

# assuing I have Portable Strawberry installed in C:\
# C:
# cd \portable
# svn export http://svn.perl.org/parrot/trunk parrot  (35492)
# cd parrot
# c:\portable\perl\bin\perl.exe Configure.pl
# mingw32-make
# cd languages\perl6
# mingw32-make
# cd ..
# rename parrot x
# copy the files from 

my $src  = "c:/portable/x";
my $dest = "c:/portable/parrot";

my @windows_files = qw(
	parrot.exe
	libparrot.dll
);
my @linux_files = qw(
	parrot
	blib/lib/libparrot.so.0.8.2
);

my @files = qw(languages/perl6/perl6.pbc);
if ($^O eq "MSWin32") {
	push @files, @windows_files;
} else {
	push @files, @linux_files;
}

# runtime and all its subdirectories

foreach my $file (@files) {
	print $file;
	chomp $file;
	next if not $file;
	my $path = dirname ($file);
	print "PATH: $path\n";
	my $dir = $path eq '.' ? $dest : File::Spec->catdir($dest, $path);
	mkpath $dir;
	copy(File::Spec->catfile($src, $file), File::Spec->catdir($dest, $path));
}

