use strict;
use warnings;

unless($ENV{AUTHOR_TEST}) {
	use Test::More skip_all => 'Author test';
}

use Test::Most;

bail_on_fail;

require File::Find::Rule;
require File::Temp;
use POSIX qw(locale_h);

$ENV{TMP_FOLDER} = File::Temp::tempdir( CLEANUP => 1 );

my $out = File::Spec->catfile($ENV{TMP_FOLDER}, 'out.txt');
my $err = File::Spec->catfile($ENV{TMP_FOLDER}, 'err.txt');

my @files = File::Find::Rule->relative->file->name('*.pm')->in('lib');
plan tests => 2 * @files;
diag "Detected locale: " . setlocale(LC_CTYPE);

foreach my $file ( @files ) {
		my $module = $file;
		$module =~ s/[\/\\]/::/g;
		$module =~ s/\.pm$//;
		if ($module eq 'Padre::CPAN') {
			skip ("Cannot load CPAN shell under the CPAN shell") for 1..2;
			next;
		}
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