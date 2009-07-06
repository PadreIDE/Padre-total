package Locale::Msgfmt::po;

use Locale::Msgfmt::Utils;

use strict;
use warnings;

our $VERSION = '0.11';

sub new {
	my $class = shift;
	return bless shift || {}, $class;
}

sub cleanup_string {
	my $str = shift;
	$str =~ s/\\n/\n/g;
	$str =~ s/\\r/\r/g;
	$str =~ s/\\t/\t/g;
	$str =~ s/\\"/"/g;
	$str =~ s/\\\\/\\/g;
	return $str;
}

sub add_string {
	my $self = shift;
	my $hash = shift;
	my %h    = %{$hash};
	return if !( defined( $h{msgid} ) && defined( $h{msgstr} ) );
	return if ( $h{fuzzy} && !$self->{fuzzy} && length( $h{msgid} ) > 0 );
	my $msgstr = join Locale::Msgfmt::Utils::null(), @{ $h{msgstr} };
	return if ( $msgstr eq "" );
	my $context;
	my $plural;

	if ( $h{msgctxt} ) {
		$context = cleanup_string( $h{msgctxt} ) . Locale::Msgfmt::Utils::eot();
	} else {
		$context = "";
	}
	if ( $h{msgid_plural} ) {
		$plural = Locale::Msgfmt::Utils::null() . cleanup_string( $h{msgid_plural} );
	} else {
		$plural = "";
	}
	$self->{mo}->add_string( $context . cleanup_string( $h{msgid} ) . $plural, cleanup_string($msgstr) );
}

sub read_po {
	my $self   = shift;
	my $pofile = shift;
	my $mo     = $self->{mo};
	open my $F, '<', $pofile or die "Could not open ($pofile) $!";
	my %h = ();
	my $type;
	while (<$F>) {
		s/\r\n/\n/;
		if (/^(msgid(?:|_plural)|msgctxt) +"(.*)" *$/) {
			$type = $1;
			if ( defined( $h{$type} ) ) {
				$self->add_string( \%h );
				%h = ();
			}
			$h{$type} = $2;
		} elsif (/^msgstr(?:\[(\d*)\])? +"(.*)" *$/) {
			$type = "msgstr";
			if ( !$h{$type} ) {
				@{ $h{$type} } = ();
			}
			push @{ $h{$type} }, $2;
		} elsif (/^"(.*)" *$/) {
			if ( $type eq "msgstr" ) {
				@{ $h{$type} }[ scalar( @{ $h{$type} } ) - 1 ] .= $1;
			} else {
				$h{$type} .= $1;
			}
		} elsif (/^ *$/) {
			$self->add_string( \%h );
			%h    = ();
			$type = undef;
		} elsif (/^#/) {
			if (/^#, fuzzy/) {
				$h{fuzzy} = 1;
			} elsif (/^#:/) {
				if ( defined( $h{msgid} ) ) {
					$self->add_string( \%h );
					%h    = ();
					$type = undef;
				}
			}
		} else {
			print "unknown line: " . $_ . "\n";
		}
	}
	$self->add_string( \%h );
	close $F;
}

sub parse {
	my $self = shift;
	my ( $pofile, $mo ) = @_;
	$self->{mo} = $mo;
	$self->read_po($pofile);
}

=head1 NAME

Locale::Msgfmt::po - class used internally by Locale::Msgfmt

=head1 SYNOPSIS

This module shouldn't be used by other software.

=head1 SEE ALSO

L<Locale::Msgfmt>

=cut

1;
