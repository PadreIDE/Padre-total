package Padre::Plugin::PerlTidy;

use strict;
use warnings;

use Perl::Tidy ();
use Wx qw(wxOK wxCENTRE);

our $VERSION = '0.01';

=head1 NAME

Padre::Plugin::PerlTidy - Format perl files using Perl::Tidy

=head1 SYNOPIS

This is a simple plugin to run Perl::Tidy on your source code.

Currently there are no customisable options (since the Padre plugin system
doesn't support that yet) - however Perl::Tidy will use your normal .perltidyrc 
file if it exists (see Perl::Tidy documentation).

=cut

my @menu = ( [ "Tidy the active document", \&on_run ], );

sub menu {
    my ( $self ) = @_;
    return @menu;
}

sub on_run {
    my ( $self, $event ) = @_;

    my $doc = $self->selected_document;

    if ( !$doc->isa( 'Padre::Document::Perl' ) ) {
        return Wx::MessageBox( 'Document is not a Perl document',
            "Error", wxOK | wxCENTRE, $self );
    }

    my $src = $self->selected_document->text_get;

    my ( $output, $stderr );

    # TODO: why doesn't stderr get captured properly?
    eval {
        Perl::Tidy::perltidy(
            argv        => \'-se',
            source      => \$src,
            destination => \$output,
            stderr      => \$stderr,
        );
    };

    if ( $@ ) {
        my $error_string = $@;
        Wx::MessageBox(
            $error_string,
            "PerlTidy Error",
            wxOK | wxCENTRE, $self
        );
    }
    else {
        $self->{ output }->AppendText( "$stderr\n" ) if defined $stderr;
        $doc->text_set( $output );
    }

    return;
}

=head1 AUTHOR

Patrick Donelan

Brian Cassidy E<lt>bricas@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2008 by Patrick Donelan http://www.patspam.com

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut

1;
