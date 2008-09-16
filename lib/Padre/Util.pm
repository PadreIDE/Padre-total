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
use Exporter ();

our $VERSION   = '0.08';
our @ISA       = 'Exporter';
our @EXPORT_OK = 'newline_type';

# Padre targets three major platforms.
# 1. Native Win32
# 2. Mac OS X
# 3. GTK Unix/Linux
# The following defined reusable constants for these platforms,
# suitable for use in platform-specific adaptation code.

use constant WIN32 => !! ( $^O eq 'MSWin32' );
use constant MAC   => !! ( $^O eq 'darwin'  );
use constant UNIX  => !  ( WIN32 or MAC );

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

1;

=head1 SUPPORT

See the support section of the main L<Padre> module.

=head1 COPYRIGHT

Copyright 2008 Gabor Szabo.

=head1 LICENSE

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl 5 itself.

=cut
