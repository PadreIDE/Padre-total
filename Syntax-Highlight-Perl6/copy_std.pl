#!/usr/bin/perl

use strict;
use warnings;
use feature 'say';
use Carp;
use File::Copy;
use Cwd;

my $PUGS = '../../pugs';
my $STD = "$PUGS/src/perl6";
my $status;

sub safe_copy {
	my ($file,$to_file) = @_;

	copy($file, $to_file)
		or croak "Could not copy $file";
}

say "\n--Running 'svn update'";
$status = system("svn update $PUGS"); 
die "Could not svn update pugs\n" if $status != 0;

my $make = $^O eq 'MSWin32' ? 'dmake.exe' : 'make';
say "\n--Running 'make clean all' for STD.pm";
my $cwd = getcwd;
chdir $STD or die "Could not change dir to $STD\n";
$status = system("$make clean all"); 
die "Could not make STD.pm\n" if $status != 0;

say 'Building and copying STD.pm files';
chdir $cwd or die "Could not change dir to $cwd\n";
safe_copy("$STD/CursorBase.pmc", 'lib/');
safe_copy("$STD/Cursor.pmc",'lib/');
safe_copy("$STD/LazyMap.pm", 'lib/LazyMap.pmc');
safe_copy("$STD/STD.pmc", 'lib/');
safe_copy("$STD/CORE.pad", 'lib/');
safe_copy("$STD/NAME.pmc", 'lib/');
safe_copy("$STD/NULL.pad", 'lib/');
safe_copy("$STD/DEBUG.pmc", 'lib/');
safe_copy("$STD/Stash.pmc", 'lib/');
safe_copy("$STD/RE_ast.pmc", 'lib/');
