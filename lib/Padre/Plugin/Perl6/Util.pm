package Padre::Plugin::Perl6::Util;

use strict;
use warnings;

our $VERSION = '0.54';

our @ISA       = 'Exporter';
our @EXPORT_OK = qw(get_perl6);

# Get perl6 full executable path
sub get_perl6 {
	my $exe_name = $^O eq 'MSWin32' ? 'perl6.exe' : 'perl6';
	require File::Which;
	my $perl6 = File::Which::which($exe_name);
	my $env_rakudo = $ENV{RAKUDO_DIR};
	if (not $perl6 && $env_rakudo) {
		$perl6 = File::Spec->catfile($env_rakudo, $exe_name);
	}

	# hard coded for the Experiemental Strawberry+Rakudo+Padre distribution
	if (not $perl6 and Padre::Constant::WIN32) {
		$perl6 = "C:\\strawberry\\six\\perl6.exe";
	}

	return -e $perl6 ? $perl6 : undef;
}

sub get_parrot_command {
	my $command = shift;
	
	my $exe_name = $^O eq 'MSWin32' ? "$command.exe" : $command;
	require File::Which;
	my $parrot_cmd = File::Which::which($exe_name);
	my $env_rakudo = $ENV{RAKUDO_DIR};
	if (not $parrot_cmd && $env_rakudo) {
		my $parrot_dir = File::Spec->catfile($env_rakudo, 'parrot');
		my $cmd = File::Spec->catfile($parrot_dir, $exe_name);
		if(-x $cmd) {
			$parrot_cmd = $cmd;
		}
	}

	return $parrot_cmd;
}

sub get_libparrot {
	my $lib_name = $^O eq 'MSWin32' ? "libparrot.dll" : 'libparrot.so';
	my $libparrot;
	my $env_rakudo = $ENV{RAKUDO_DIR};
	if ($env_rakudo) {
		my $parrot_dir = File::Spec->catfile($env_rakudo, 'parrot');
		my $lib = File::Spec->catfile($parrot_dir, $lib_name);
		if(-e $lib) {
			$libparrot = $lib;
		}
	}

	return $libparrot;
}

1;

__END__

=head1 AUTHOR

Ahmad M. Zawawi C<< <ahmad.zawawi at gmail.com> >>

Gabor Szabo L<http://szabgab.com/>

=head1 COPYRIGHT AND LICENSE

Copyright 2008-2009 Padre Developers as in Perl6.pm

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl 5 itself.