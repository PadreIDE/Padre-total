#!/usr/bin/perl
use strict;
use warnings;

# check if there are versions in every module and if they are in the same
# allow updating version numbers to one specific version.

use autodie qw(:default system);
# needs IPC::System::Simple

use File::Temp ();
use File::Find  qw(find);
use File::Slurp qw(read_file write_file);
use File::Copy  qw(copy);

my $TRUNK = "http://svn.perlide.org/padre/trunk";
my $TAGS  = "http://svn.perlide.org/padre/tags";
my $error = 0;

my ($rev, $version, $tag) = @ARGV;
die "Usage: $0 REV VERSION [--tag]\n"
	if not $version or $version !~ /^\d\.\d\d$/ or $rev !~ /^\d+$/;

my $dir = File::Temp::tempdir( CLEANUP => 1 );
chdir $dir;
print "DIR $dir\n";

_system("svn export --quiet -r$rev $TRUNK padre");
chdir 'padre';
_system("msgfmt -o share/locale/de.mo share/locale/de.po");
# TODO add de.po to MANIFEST
if (open my $fh, '>>', 'MANIFEST') {
	print {$fh} "\nshare/locale/de.mo\n";
	close $fh;
}

#print "Setting VERSION $version\n";
find(\&check_version, 'lib');
die if $error;

_system("$^X Build.PL");
_system("$^X Build");
_system("$^X Build test");
_system("$^X Build dist");
copy("Padre-$version.tar.gz", "/home/gabor/tmp") or die $!;
if ($tag) {
	_system("svn cp -r$rev $TRUNK $TAGS/Padre-$version -m'tag Padre-$version'");
}
chdir "/home/gabor/tmp";


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
	system $cmd;
}
