use strict;
use warnings;

use Test::Most;

unless($ENV{AUTHOR_TEST}) {
	plan skip_all => 'Author test';
}

bail_on_fail;

require File::Find::Rule;
require File::Temp;
use POSIX qw(locale_h);

my $TMP_FOLDER = File::Temp::tempdir( CLEANUP => 1 );
my $out = File::Spec->catfile($TMP_FOLDER, 'out.txt');
my $err = File::Spec->catfile($TMP_FOLDER, 'err.txt');

my @files = File::Find::Rule->relative->file->name('*.pm')->in('lib');
plan tests => 2 * @files;
diag "Detected locale: " . setlocale(LC_CTYPE);

foreach my $file ( @files ) {
		my $module = $file;
		$module =~ s/[\/\\]/::/g;
		$module =~ s/\.pm$//;

		system "$^X -e \"require $module; print 'ok';\" > $out 2>$err";
		my $err_data = slurp($err);
		is($err_data, '', "STDERR of $file");

		my $out_data = slurp($out);
		is($out_data, 'ok', "STDOUT of $file");
}

sub slurp {
	my $file = shift;
	open my $fh, '<', $file or die $!;
	local $/ = undef;
	return <$fh>;
}