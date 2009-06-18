package lib::Tools;
use strict;
use warnings;

use base 'Exporter';
our @EXPORT = qw(convert_po_to_mo);

sub convert_po_to_mo {
	my $path   = shift;
	
	my $msgfmt = get_msgfmt();
	return if not $msgfmt;

	my @mo;
	if ( $^O eq 'MSWin32' ) {
		@mo = map {
			substr( File::Basename::basename($_), 0, -3 )
		} File::Glob::Windows::glob("$path/share/locale/*.po");
	} else {
		@mo = map {
			substr( File::Basename::basename($_), 0, -3 )
		} glob "$path/share/locale/*.po";
	}
	foreach my $locale ( @mo ) {
		system(
			$msgfmt, "-o",
			"$path/share/locale/$locale.mo",
			"$path/share/locale/$locale.po",
		);
	}
}

sub get_msgfmt {

	my $msgfmt;
	if ( $^O =~ /(linux|bsd)/ ) {
		$msgfmt = scalar File::Which::which('msgfmt');
	} elsif ( $^O eq 'MSWin32' ) {
		eval {
			require File::Glob::Windows;
		};
		if( $@ ) {
			die("Default glob() will misinterpret spaces in folder names as seperators, install File::Glob::Windows to fix this behavior!");
		}
		my $p = "C:/Program Files/GnuWin32/bin/msgfmt.exe";
		if ( -e $p ) {
			$msgfmt = $p;
		} else {
			$msgfmt = scalar File::Which::which('msgfmt');
		}
	}
	
	return $msgfmt;
}

1;
