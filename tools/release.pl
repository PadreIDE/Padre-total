#!/usr/bin/perl
use strict;
use warnings;

# check if there are versions in every module and if they are in the same
# allow updating version numbers to one specific version.

use autodie qw(:default system);
# needs IPC::System::Simple

use Cwd            ();
use File::Basename ();
use File::Copy     qw(copy);
use File::Find     qw(find);
use File::Slurp    qw(read_file write_file);
use File::Temp     ();
use FindBin;

use lib "$FindBin::Bin/../Padre";
use privlib::Tools;

my $SVN     = "http://svn.perlide.org/padre";
my $TAGS    = "http://svn.perlide.org/padre/tags";
my $error   = 0;

my ($rev, $version, $tag) = @ARGV;
die "Usage: $0 REV VERSION [--tag]\n"
	if not $version or $version !~ /^\d\.\d\d$/ or $rev !~ /^\d+$/;

my $start_dir = Cwd::cwd();

my ($URL) = grep {/^URL:\s*/} qx{LC_ALL=C svn info};
die "no url" if not $URL;
chomp $URL;
$URL =~ s/^URL:\s*//;


my $name;
my $ver;

# URL can be .../trunk/Name     or ../trunk/Name-More-Name
# or    .../branches/Name or .../barnches/Name-0.12  or the others
if ($URL =~ m{$SVN/(trunk|branches)/([^/]+)$}) {
	$name = $2;
	if ($name =~ /^([\w-]+)-(\d+\.\d+(_\d+)?)$/) {
		$name = $1;
		$ver  = $2;
	}
}

#my $name = File::Basename::basename($start_dir);
die "No name" if not $name;

print "name: $name\n";
print "ver: $ver\n" if $ver;
if ($ver and $ver ne $version) {
	die "Invalid version $ver - $version\n";
}

my $dir = File::Temp::tempdir( CLEANUP => 0 );
chdir $dir;
print "DIR $dir\n";

_system("svn export --quiet -r$rev $URL src");
chdir 'src';

my $locale_path;
if (-d 'share/locale') {
	$locale_path = Cwd::cwd();
} else {
	(my $path = $name) =~ s{-}{/}g;
	if (-d "lib/$path/share/locale") {
		$locale_path = Cwd::cwd() . "/lib/$path";
	}
}

if ($locale_path) {
	print "locale path: '$locale_path'\n";
	convert_po_to_mo($locale_path);
}

#print "Setting VERSION $version\n";
find(\&check_version, 'lib');
die if $error;

my $make         = $^O eq 'freebsd' ? 'HARNESS_DEBUG=1 gmake' : 'make';
my $makefile_pl  = "Makefile.PL";
if(-f "Build.PL") {
	$makefile_pl = "Build.PL";
	$make = "./Build";
}
_system("$^X $makefile_pl");
_system("$make");
_system("$make manifest");
_system("$make test");
_system("$make disttest");

if ($^O ne 'MSWin32') {
	print "Turn off DISPLAY\n";
	local $ENV{DISPLAY} = undef;
	_system("$make disttest");
}

_system("$make dist");
copy("$name-$version.tar.gz", $start_dir) or die $!;
if ($tag) {
	_system("svn cp -r$rev $URL $TAGS/$name-$version -m'tag $name-$version'");
}
chdir $start_dir;


sub check_version {
    return if $File::Find::name =~ /\.svn/;
    return if $_ !~ /\.pm/;
    my @data = read_file($_);
    if (my ($line) = grep {$_ =~ /^our \$VERSION\s*=\s*'\d+\.\d\d';/ } @data ) {
		if ($line !~ /^(our \$VERSION\s*=\s*)'$version';/ ) {
			chomp $line;
			warn "Invalid VERSION in $File::Find::name  ($line)\n";
			$error++;
		}
    } else {
       warn "No VERSION in $File::Find::name\n";
       $error++;
    }
    return;
}

sub _system {
	my $cmd = shift;
	print "$cmd\n";
	system($cmd);
}
