#!/usr/bin/env perl

use strict;
use warnings;

use File::Find;

# either pass in a year to change to or use this year
my $path = $ARGV[0] || die("You must provide the path to the Padre directory");
my $this_year = $ARGV[1] || (localtime)[5] + 1900;

# this is what we are looking for:
# Copyright 2008-\d{4} The Padre development team as listed in Padre.pm.

print "Setting year to $this_year.";

my @ignore = ('.svn', 'blib');

my @files;

find(\&files, $path);

foreach my $file( @files ) {
	print "Checking: $file\n";
	open( my $fh, '<', $file ) or die "Failed to open $file: $!\n";
	my @contents = <$fh>;
	close( $fh );
	my $changed = 0;
	foreach my $line( @contents ) {
		if( $line =~ m/(.*Copyright 2008-)(\d{4})( The Padre development team as listed in Padre\.pm\..*)/)  {
			$line = "$1$this_year$3\n";
			$changed = 1;
		}
	}
	
	if( $changed ) {
		print "*** $file has changed = $changed\n";
		open( my $fh, '>', $file ) or die( "Failed to open the file for writing $file: $!\n" );
		print  $fh @contents;
		close($fh) or die( "Failed to close the file $file: $!\n");
	}
		
}

sub files {
	
	my $file = $File::Find::name;
	if( ! ignore_file($file) ) {
		push @files, $file;
	}
}

sub ignore_file {
	my $file = shift;
	my $ignore = 0;
	foreach my $pat( @ignore ) {
		if( $file =~ m/$pat/ ) {
			$ignore = 1;
			last;
		}
	}
	return $ignore;
	
}
