#!/usr/bin/env perl
use strict;
use warnings;

# check if there are versions in every module and if they are in the same
# allow updating version numbers to one specific version.

use Env::Sanctify;
use autodie qw(:default system);

# needs IPC::System::Simple

use Cwd            ();
use File::Basename ();
use File::Copy qw(copy);
use File::Find qw(find);
use File::Slurp qw(read_file write_file);
use File::Temp ();
use FindBin;

use lib "$FindBin::Bin/../Padre";
use privlib::Tools;

use Getopt::Long;

my $SVN   = "http://svn.perlide.org/padre";
my $TAGS  = "http://svn.perlide.org/padre/tags";
my $error = 0;


# options
my $path    = '';
my $rev     = 'HEAD';
my $version = '';
my $tag     = '';
my $display = 0;

## options checking
GetOptions(
	'path=s'     => \$path,
	'tag'        => \$tag,
	'version=s'  => \$version,
	'revision=s' => \$rev,
	'display'    => \$display,
);


#my ( $rev, $version, $tag ) = @ARGV;
#die "Usage: $0 REV VERSION [--tag]\n"
if (   not $version
	or $version !~ /^\d\.\d\.?\d$/
	or $rev !~ /^(?:r?\d+|HEAD)$/ )
{
	usage();
	exit 1;
}




sub usage {
	print <<EOM;
Usage: release.pl --version <Your Release Version Number>

Optional Parameters:
--path <Path to the directory of component to release - typically a Plugin>
--tag  <will try to create a distribution using a temporary directory and copy the resulting Padre-X.XX.tar.gz in the current directory>
--revision <SVN Revision Number, defaults to HEAD (note: not BASE)>
--display  will skip the tests without DISPLAY

Full details on the wiki: http://padre.perlide.org/trac/wiki/Release

EOM

}

if ($tag) {
	print "Setting tag for this release\n";
}

my $start_dir;
if ( $path && -d $path ) {
	$start_dir = $path;
} elsif ( $path && !-d $path ) {
	die("\n\nERROR: $path does not exist\n\n");
} else {
	$start_dir = Cwd::cwd();
}

print "Start dir: $start_dir\n";

my @svn_info = ( $^O ne 'MSWin32' ) ? qx{LC_ALL=C svn info $start_dir} : qx{svn info $start_dir};
my ($URL) = grep {/^URL:\s*/} @svn_info;
die "no url" if not $URL;
chomp $URL;
$URL =~ s/^URL:\s*//;

my $name;
my $ver;

# URL can be .../trunk/Name     or ../trunk/Name-More-Name
# or    .../branches/Name or .../barnches/Name-0.12  or the others
# of course this breaks when you use release-0.82 in the branch
# and the make dist created Padre-0.82  so best to change
# what name is used when branching.
if ( $URL =~ m{$SVN/(trunk|branches)/([^/]+)$} ) {
	$name = $2;
	if ( $name =~ /^([\w-]+)-(\d+\.\d+(_\d+)?)$/ ) {
		$name = $1;
		$ver  = $2;
	}
}

#my $name = File::Basename::basename($start_dir);
die "No name" if not $name;

print "name: $name\n";
print "ver: $ver\n" if $ver;
if ( $ver and $ver ne $version ) {
	die "Invalid version $ver - $version\n";
}

my $tmp_dir = File::Temp::tempdir( CLEANUP => 0 );
chdir $tmp_dir;
print "\n**DIR $tmp_dir\n";

# Added /Padre to the destination path, as this allows
# assumptions in Padre::Share::share to create the
# correct rel2abs path.
if ($name eq 'Padre') {
	_system("svn export --quiet -r$rev $URL src/Padre");
	chdir 'src/Padre';
} else {
	_system("svn export --quiet -r$rev $URL $name");
	chdir $name;
}

print "CWD: " . Cwd::cwd() . "\n";

print "\n**Checking VERSION for $version\n";
find( \&check_version, 'lib' );
die if $error;

my $make = $^O eq 'freebsd' ? 'HARNESS_DEBUG=1 gmake' : 'make';
my $makefile_pl = "Makefile.PL";
if ( -f "Build.PL" ) {
	$makefile_pl = "Build.PL";
	$make = ( $^O ne 'MSWin32' ) ? "./Build" : "Build.bat";
}
_system("$^X $makefile_pl");
_system("$make");
_system("$make manifest");

# check and set RELEASE_TESTING if needs be
my $sanc;
print "\n**RELEASE_TESTING envorinment variable is: ";
if ( !defined( $ENV{RELEASE_TESTING} ) ) {
	print "not set... setting RELEASE_TESTING\n";
	$sanc = Env::Sanctify->sanctify( env => { RELEASE_TESTING => 1 } );
} else {
	print "set to " . $ENV{RELEASE_TESTING} . "\n";
	print "Release Testing will ";
	if ( !$ENV{RELEASE_TESTING} ) {
		print "NOT ";
	}
	print " be done this pass.\n";
}
print "\n**make test**\n";
_system("$make test");

print "\n**Doing disttest - with DISPLAY set.\n";
_system("$make disttest");


# restore the environment for RELEASE_TESTING
if ( defined($sanc) ) {
	$sanc->restore;
}

# check if we have set the display from the command line.
if ( not $display ) {
	print "\n**\$display not set\n";
	if ( $^O ne 'MSWin32' && defined( $ENV{DISPLAY} ) ) {
		print "\n***Turn off DISPLAY for packagers disttest-ing.\n";

		# DISPLAY is turned off here to make sure disttest runs without it for various packagers ( such a Fedora )
		# which require tests to pass, so any tests that fail here complaining it's needs a DISPLAY variable set
		# needs to be updated with a check for DISPLAY and skip when missing.
		my $sanctify = Env::Sanctify->sanctify( sanctify => ['DISPLAY'] );
		print "\n\n*** make disttest ***\n\n";
		_system("$make disttest");
		$sanctify->restore();
	}
}

print "Now making the distribution\n";

_system("$make dist");
print "current working dir... " . Cwd::cwd() . "\n";
if ($name ne 'Padre') {
	$tmp_dir .= "/$name";
}
print "Copying the release tar ball back to start dir: $tmp_dir/$name-$version.tar.gz, $start_dir\n";
copy( "$tmp_dir/$name-$version.tar.gz", $start_dir ) or die $!;
if ($tag) {
	_system("svn cp -r$rev $URL $TAGS/$name-$version -m'tag $name-$version'");
}
chdir $start_dir;

sub check_version {
	return if $File::Find::name =~ /\.svn/;
	return if $_ !~ /\.pm/;
	my @data = read_file($_);

	# someone has moved the $VERSION into a BEGIN{} block.
	# until this is sorted out the strict searching for 'our $VERSION' has be be removed.
	#if ( my ($line) = grep { $_ =~ /^our \$VERSION\s*=\s*'\d+\.\d\.?\d';/ } @data ) {
	if ( my ($line) = grep { $_ =~ /\$VERSION\s*=\s*'\d+\.\d\.?\d';/ } @data ) {

		#if ( $line !~ /^(our \$VERSION\s*=\s*)'$version';/ ) {
		if ( $line !~ /(\$VERSION\s*=\s*)'$version';/ ) {
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
