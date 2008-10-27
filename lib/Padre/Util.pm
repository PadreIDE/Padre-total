package Padre::Util;

=pod

=head1 NAME

Padre::Util - Padre Utility Functions

=head1 DESCRIPTION

The Padre::Util package is a internal storage area for miscellaneous
functions that aren't really Padre-specific that we want to throw
somewhere it won't clog up task-specific packages.

All functions are exportable and documented for maintenance purposes,
but except for in the Padre core distribution you are discouraged in
the strongest possible terms for relying on these functions, as they
may be moved, removed or changed at any time without notice.

=head1 FUNCTIONS

=cut

use 5.008;
use strict;
use warnings;
use Exporter     ();
use List::Util   qw(first);

our $VERSION   = '0.14';
our @ISA       = 'Exporter';
our @EXPORT_OK = qw(newline_type get_matches);

# Padre targets three major platforms.
# 1. Native Win32
# 2. Mac OS X
# 3. GTK Unix/Linux
# The following defined reusable constants for these platforms,
# suitable for use in platform-specific adaptation code.

use constant WIN32   => !! ( $^O eq 'MSWin32' );
use constant MAC     => !! ( $^O eq 'darwin'  );
use constant UNIX    => !  ( WIN32 or MAC );
use constant NEWLINE => WIN32 ? 'WIN' : MAC ? 'MAX' : 'UNIX';

=pod

=head2 newline_type

  my $type = newline_type( $string );

Returns None if there was not CR or LF in the file.

Returns UNIX, Mac or Windows if only the appropriate newlines were found.

Returns Mixed if line endings are mixed.

=cut

sub newline_type {
	my $text = shift;

	my $CR   = "\015";
	my $LF   = "\012";
	my $CRLF = "\015\012";

	return "None" if $text !~ /$LF/ and $text !~ /$CR/;
	return "UNIX" if $text !~ /$CR/;
	return "MAC"  if $text !~ /$LF/;

	$text =~ s/$CRLF//g;
	return "WIN" if $text !~ /$LF/ and $text !~ /$CR/;

	return "Mixed"
}

sub get_matches {
	my ($text, $regex, $from, $to, $backward) = @_;
	die "missing parameters" if @_ < 4;

	my @matches;

	while ($text =~ /$regex/g) {
		my $e = pos($text);
		my $s = $e - length($&);
		push @matches, [$s, $e];
	}

	my $pair;
	if ($backward) {
		$pair = first {$to > $_->[1]} reverse @matches;
		if (not $pair and @matches) {
			$pair = $matches[-1];
		}
	} else {
		$pair = first {$from < $_->[0]}         @matches;
		if (not $pair and @matches) {
		    $pair = $matches[0];
		}
	}

	my ($start, $end);
	($start, $end) = @$pair if $pair;

	return ($start, $end, @matches);
}

1;

=head1 SUPPORT

See the support section of the main L<Padre> module.

=head1 COPYRIGHT

Copyright 2008 Gabor Szabo.

=head1 LICENSE

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl 5 itself.

=cut
