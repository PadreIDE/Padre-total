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

my @menu = (
    [ 'Tidy the active document', \&tidy_document ],
    [ 'Tidy the selected text',   \&tidy_selection ]
);

sub menu {
    return @menu;
}

sub _tidy {
    my ( $self, $src ) = @_;

    return unless defined $src;

    my $doc = $self->selected_document;

    if ( !$doc->isa( 'Padre::Document::Perl' ) ) {
        return Wx::MessageBox( 'Document is not a Perl document',
            "Error", wxOK | wxCENTRE, $self );
    }

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
        return;
    }

    $self->{ output }->AppendText( "$stderr\n" ) if defined $stderr;
    return $output;
}

sub tidy_selection {
    my ( $self, $event ) = @_;
    my $src = $self->selected_text;

    my $newtext = _tidy( $self, $src );

    return unless defined $newtext && length $newtext;

    $newtext =~ s{\n$}{};

    my $editor = $self->selected_editor;
    $editor->ReplaceSelection( $newtext );
}

sub tidy_document {
    my ( $self, $event ) = @_;

    my $doc = $self->selected_document;
    my $src = $doc->text_get;

    my $newtext = _tidy( $self, $src );

    return unless defined $newtext && length $newtext;

    $doc->text_set( $newtext );
}

=head1 INSTALLATION

You can install this module like any other Perl module and it will
become available in your Padre editor. However, you can also
choose to install it into your user's Padre configuration directory only.
The necessary steps are outlined in the C<README> file in this distribution.

Essentially, you do C<perl Build.PL> and C<./Build installplugin>.

=head1 AUTHOR

Patrick Donelan

Brian Cassidy E<lt>bricas@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2008 by Patrick Donelan http://www.patspam.com

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut

1;
