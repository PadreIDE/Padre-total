package Padre::Plugin::Perl6::Util;

use strict;
use warnings;

our $VERSION = '0.40';

our @ISA       = 'Exporter';
our @EXPORT_OK = qw(get_perl6);

use Padre ();

# Get perl6 full executable path
sub get_perl6 {
	my $exe_name = $^O eq 'MSWin32' ? 'perl6.exe' : 'perl6';
	require File::Which;
	my $perl6 = File::Which::which($exe_name);
	if (not $perl6) {
		if (not $ENV{RAKUDO_DIR}) {
			my $main = Padre->ide->wx->main;
			$main->error("Either $exe_name needs to be in the PATH or RAKUDO_DIR must point to the directory of the Rakudo checkout.");
		}
		$perl6 = File::Spec->catfile($ENV{RAKUDO_DIR}, $exe_name);
	}

	return $perl6;
}
