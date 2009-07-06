package Locale::Msgfmt;

use Locale::Msgfmt::mo;
use Locale::Msgfmt::po;
use File::Path;
use File::Spec;

use strict;
use warnings;

use base 'Exporter';

our @EXPORT = qw/msgfmt/;

our $VERSION = '0.10';

sub msgfmt {
	my $hash = shift;
	if ( !defined($hash) ) {
		die("error: must give input");
	}
	if ( !( ref($hash) eq "HASH" ) ) {
		$hash = { in => $hash };
	}
	if ( !defined( $hash->{in} ) or !length( $hash->{in} ) ) {
		die("error: must give an input file");
	}
	if ( !-e $hash->{in} ) {
		die("error: input does not exist");
	}
	if ( -d $hash->{in} ) {
		return _msgfmt_dir($hash);
	} else {
		return _msgfmt($hash);
	}
}

sub _msgfmt {
	my $hash = shift;
	if ( !defined( $hash->{in} ) ) {
		die("error: must give an input file");
	}
	if ( !-f $hash->{in} ) {
		die("error: input file does not exist");
	}
	if ( !defined( $hash->{out} ) ) {
		if ( $hash->{in} =~ /\.po$/ ) {
			$hash->{out} = $hash->{in};
			$hash->{out} =~ s/po$/mo/;
		} else {
			die("error: must give an output file");
		}
	}
	my $mo = Locale::Msgfmt::mo->new();
	$mo->initialize();
	my $po = Locale::Msgfmt::po->new( { fuzzy => $hash->{fuzzy} } );
	$po->parse( $hash->{in}, $mo );
	$mo->prepare();
	$mo->out( $hash->{out} );
	print $hash->{in} . " -> " . $hash->{out} . "\n" if ( $hash->{verbose} );
	unlink( $hash->{in} ) if ( $hash->{remove} );
}

sub _msgfmt_dir {
	my $hash = shift;
	if ( !-d $hash->{in} ) {
		die("error: input directory does not exist");
	}
	if ( !defined( $hash->{out} ) ) {
		$hash->{out} = $hash->{in};
	}
	if ( !-d $hash->{out} ) {
		File::Path::mkpath( $hash->{out} );
	}
	opendir my $D, $hash->{in} or die "Could not open ($hash->{in}) $!";
	my @list = readdir $D;
	closedir $D;
	my @removelist = ();
	if ( $hash->{remove} ) {
		@removelist = grep /\.pot$/, @list;
	}
	@list = grep /\.po$/, @list;
	my %files;
	foreach (@list) {
		my $in = File::Spec->catfile( $hash->{in}, $_ );
		my $out = File::Spec->catfile( $hash->{out}, substr( $_, 0, -3 ) . ".mo" );
		$files{$in} = $out;
	}
	foreach ( keys %files ) {
		my %newhash = ( %{$hash} );
		$newhash{in}  = $_;
		$newhash{out} = $files{$_};
		_msgfmt( \%newhash );
	}
	foreach (@removelist) {
		my $f = File::Spec->catfile( $hash->{in}, $_ );
		print "-$f\n" if ( $hash->{verbose} );
		unlink($f);
	}
}

1;

=head1 NAME

Locale::Msgfmt - Compile .po files to .mo files

=head1 SYNOPSIS

This module does the same thing as msgfmt from GNU gettext-tools,
except this is pure Perl. The interface is best explained through
examples:

    use Locale::Msgfmt;

    # compile po/fr.po into po/fr.mo
    msgfmt({in => "po/fr.po", out => "po/fr.mo"});
    # compile po/fr.po into po/fr.mo and include fuzzy translations
    msgfmt({in => "po/fr.po", out => "po/fr.mo", fuzzy => 1});
    # compile all the .po files in the po directory, and write the .mo
    # files to the po directory
    msgfmt("po/");
    # compile all the .po files in the po directory, and write the .mo
    # files to the po directory, and include fuzzy translations
    msgfmt({in => "po/", fuzzy => 1});
    # compile all the .po files in the po directory, and write the .mo
    # files to the output directory, creating the output directory if
    # it doesn't already exist
    msgfmt({in => "po/", out => "output/"});
    # compile all the .po files in the po directory, and write the .mo
    # files to the output directory, and include fuzzy translations
    msgfmt({in => "po/", out => "output/", fuzzy => 1});
    # compile po/fr.po into po/fr.mo
    msgfmt("po/fr.po");
    # compile po/fr.po into po/fr.mo and include fuzzy translations
    msgfmt({in => "po/fr.po", fuzzy => 1});

=head1 COPYRIGHT & LICENSE

Copyright 2009 Ryan Niebur, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut
