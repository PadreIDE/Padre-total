#!/usr/bin/env perl 
use strict;
use warnings;
use 5.010;


# See http://padre.perlide.org/trac/wiki/BuildingOnPortableStrawberry
# for instructions

# This script assumes that Strawberry Perl was installed in c:\strawberry
# and that it is NOT a portable version

my $zip_file = shift or die "Usage: $0 TARGET_ZIP_FILENAME\n";


use File::Path::Tiny;

my $root = "c:/strawberry";
unlink glob "$root/cpan/cpan_sqlite_log.*";
foreach my $dir (qw(build sources Bundle)) {
	File::Path::Tiny::rm("$root/cpan/$dir");
}
File::Path::Tiny::rm("$root/perl/bin/lex"); # Perl6 

#use File::Find qw(find);
use Archive::Zip;

zip();

sub zip {
    my $verbose = 0;
    my @files;
    #find( sub { push @files, $File::Find::name;
    #            print $File::Find::name.$/ if $verbose }, $root );
	my $zip = Archive::Zip->new;
	$zip->addTree($root);
	$zip->writeToFileNamed($zip_file);
}

#my $cmd = "$root/perl/bin/ptar -czf $file $root";
#say $cmd;
#system $cmd;

