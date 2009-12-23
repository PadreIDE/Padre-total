#!/pro/bin/perl
# By Tux

use strict;
use warnings;

use Date::Manip;
use Data::Peek;
use File::Find;
my $pod;
find (sub { $_ eq "perllocal.pod" and $pod //= $File::Find::name }, @INC);

$pod or die "Cannot find perllocal.pod\n";

my %m;
open my $ph, "<", $pod or die "Cannot open pod: $!\n";
local $/ = "\n=back\n";
while (<$ph>) {
    m/=head2\s+(.*?):\s+C<\s*(.*?)\s*>\s*L<\s*(.*?)\|/ or next;
    my ($date, $type, $mod, $lt, $vsn, $exe, $id) = ($1, $2, $3, "", "", "", "");
    m/installed into:\s*(.*)/		and $id  = $1;
    m/C<\s*LINKTYPE\s*:\s*(.*?)\s*>/	and $lt  = $1;
    m/C<\s*VERSION\s*:\s*(.*?)\s*>/	and $vsn = $1;
    m/C<\s*EXE_FILES\s*:\s*(.*?)\s*>/	and $exe = $1;
    push @{$m{$mod}}, {
	stamp		=> UnixDate ($date, "%s"),
	date		=> $date,
	version		=> $vsn,
	type		=> $type,
	linktype	=> $lt,
	exe_files	=> $exe,
	inst_dir	=> $id,
	};
    }
close $ph;

DDumper \%m;
