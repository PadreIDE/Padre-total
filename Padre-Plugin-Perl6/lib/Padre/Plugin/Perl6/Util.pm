package Padre::Plugin::Perl6::Util;

use strict;
use warnings;
use Padre::Constant ();

our $VERSION = '0.55';

# Get perl6 full executable path
sub perl6_exe {
	my $exe = Padre::Constant::WIN32 ? 'perl6.exe' : 'perl6';

	# Look for the explicit environment variable
	if ( $ENV{RAKUDO_DIR} ) {
		my $perl6 = File::Spec->catfile( $ENV{RAKUDO_DIR}, $exe );
		if ( -f $perl6 and -x _ ) {
			return $perl6;
		}
	}

	# On Windows, look for the Six distribution
	if (Padre::Constant::WIN32) {
		my $perl6 = "C:\\strawberry\\six\\perl6.exe";
		if ( -f $perl6 ) {
			return $perl6;
		}
	}

	# Look on the path
	require File::Which;
	my $perl6 = File::Which::which('perl6');
	if ( defined $perl6 and -f $perl6 and -x _ ) {
		return $perl6;
	}

	return undef;
}

sub parrot_bin {
	my $bin = shift;
	my $exe = Padre::Constant::WIN32 ? "$bin.exe" : $bin;

	# Look for the explicit RAKUDO_DIR
	if ( $ENV{RAKUDO_DIR} ) {
		my $command = File::Spec->catfile( $ENV{RAKUDO_DIR}, 'parrot', $exe );
		if ( -f $command and -x _ ) {
			return $command;
		}
	}

	# On Windows, look for the Six distribution
	if (Padre::Constant::WIN32) {
		my $command = "C:\\strawberry\\six\\parrot\\$exe";
		if ( -f $command and -x _ ) {
			return $command;
		}
	}

	# Look in the path for the command, fwiw
	require File::Which;
	my $command = File::Which::which($bin);
	if ( $command and -f $command and -x _ ) {
		return $command;
	}

	return undef;
}

sub libparrot {
	my $lib = Padre::Constant::WIN32 ? "libparrot.dll" : 'libparrot.so';

	# Look for the explicit RAKUDO_DIR
	if ( $ENV{RAKUDO_DIR} ) {
		my $libparrot = File::Spec->catfile( $ENV{RAKUDO_DIR}, 'parrot', $lib );
		if ( -f $libparrot ) {
			return $libparrot;
		}
	}

	# On Windows, look for the Six distribution
	if (Padre::Constant::WIN32) {
		my $libparrot = "C:\\strawberry\\six\\parrot\\libparrot.dll";
		if ( -f $libparrot ) {
			return $libparrot;
		}
	}

	return undef;
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
