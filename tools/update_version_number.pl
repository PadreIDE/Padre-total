#!/usr/bin/env perl
use strict;
use warnings;


# check if there are versions in every module and if they are in the same
# allow updating version numbers to one specific version.

use File::Find qw(find);
use File::Slurp qw(read_file write_file);

my $version = shift;

# 0.12  or 0.23.12 or 0.1223
my $VREG = qr{\d+\.\d+(\.\d+)?};

die "Usage: $0 VERSION\n" if not $version or $version !~ /^$VREG$/;
print "Setting VERSION $version\n";

find( \&xversion, 'lib' );


sub xversion {
	return if $File::Find::name =~ /\.svn/;
	return if $_ !~ /\.pm/;
	my @data = read_file($_);
	if ( grep { $_ =~ /^our \$VERSION\s*=\s*'$VREG';/ } @data ) {
		my @new = map { $_ =~ s/^(our \$VERSION\s*=\s*)'$VREG';/$1'$version';/; $_ } @data;
		write_file( $_, @new );
	} else {
		warn "No VERSION in $File::Find::name\n";
	}
}

