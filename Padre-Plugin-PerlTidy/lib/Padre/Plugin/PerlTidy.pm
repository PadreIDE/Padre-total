package Padre::Plugin::PerlTidy;

use strict;
use warnings;

use base 'Padre::Plugin';

use Padre::Wx ();

our $VERSION = '0.03';

=head1 NAME

Padre::Plugin::PerlTidy - Format perl files using Perl::Tidy

=head1 SYNOPIS

This is a simple plugin to run Perl::Tidy on your source code.

Currently there are no customisable options (since the Padre plugin system
doesn't support that yet) - however Perl::Tidy will use your normal .perltidyrc 
file if it exists (see Perl::Tidy documentation).

=cut

sub padre_interfaces {
	'Padre::Plugin' => '0.21',
}

sub menu_plugins_simple {
    PerlTidy => [
        Wx::gettext('Tidy the active document') => \&tidy_document,
        Wx::gettext('Tidy the selected text')   => \&tidy_selection,
        Wx::gettext('Export active document to HTML file') => \&export_document,
        Wx::gettext('Export selected text to HTML file')   => \&export_selection,
    ];
}

sub _tidy {
    my ( $self, $src ) = @_;

    require Perl::Tidy;

    return unless defined $src;

    my $doc = $self->selected_document;

    if ( !$doc->isa( 'Padre::Document::Perl' ) ) {
        return Wx::MessageBox( 'Document is not a Perl document',
            "Error", Wx::wxOK | Wx::wxCENTRE, $self );
    }

    my ( $output, $error );

    # TODO: suppress the senseless warning from PerlTidy
    eval {
        Perl::Tidy::perltidy(
            argv        => \'',
            source      => \$src,
            destination => \$output,
            errorfile   => \$error,
        );
    };

    if ( $@ ) {
        my $error_string = $@;
        Wx::MessageBox(
            $error_string,
            "PerlTidy Error",
            Wx::wxOK | Wx::wxCENTRE, $self
        );
        return;
    }

    if ( defined $error ) {
        my $width = length( $doc->filename ) + 2;
        $self->{ gui }->{ output_panel }->AppendText(
            "\n\n" . "-" x $width . "\n" . $doc->filename . "\n" . "-" x $width . "\n" );
        $self->{ gui }->{ output_panel }->AppendText( "$error\n" );
        $self->{ gui }->{ output_panel }->select;
    }
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

sub _get_filename {
    my $self = shift;

    my $doc     = $self->selected_document or return;
    my $current = $doc->filename;
    my $default_dir = '';

    if ( defined $current ) {
        require File::Basename;
        $default_dir = File::Basename::dirname($current);
    }

    require File::Spec;

    while (1) {
        my $dialog = Wx::FileDialog->new(
            $self,
            Wx::gettext("Save file as..."),
            $default_dir,
            $doc->filename . '.html',
            "*.*",
            Wx::wxFD_SAVE,
        );
        if ( $dialog->ShowModal == Wx::wxID_CANCEL ) {
            return;
        }
        my $filename = $dialog->GetFilename;
        $default_dir = $dialog->GetDirectory;
        my $path = File::Spec->catfile($default_dir, $filename);
        if ( -e $path ) {
            my $res = Wx::MessageBox(
                Wx::gettext("File already exists. Overwrite it?"),
                Wx::gettext("Exist"),
                Wx::wxYES_NO,
                $self,
            );
            if ( $res == Wx::wxYES ) {
                return $path;
            }
        } else {
            return $path;
        }
    }
}

sub _export {
    my ( $self, $src ) = @_;

    require Perl::Tidy;

    return unless defined $src;

    my $doc = $self->selected_document;

    if ( !$doc->isa( 'Padre::Document::Perl' ) ) {
        return Wx::MessageBox( 'Document is not a Perl document',
            "Error", Wx::wxOK | Wx::wxCENTRE, $self );
    }

    my $filename = _get_filename($self);

    return unless defined $filename;

    my ( $output, $error );

    # TODO: suppress the senseless warning from PerlTidy
    eval {
        Perl::Tidy::perltidy(
            argv        => \'-html -nnn',
            source      => \$src,
            destination => $filename,
            errorfile   => \$error,
        );
    };

    if ( $@ ) {
        my $error_string = $@;
        Wx::MessageBox(
            $error_string,
            "PerlTidy Error",
            Wx::wxOK | Wx::wxCENTRE, $self
        );
        return;
    }

    if ( defined $error ) {
        my $width = length( $doc->filename ) + 2;
        $self->{ gui }->{ output_panel }->AppendText(
            "\n\n" . "-" x $width . "\n" . $doc->filename . "\n" . "-" x $width . "\n" );
        $self->{ gui }->{ output_panel }->AppendText( "$error\n" );
        $self->{ gui }->{ output_panel }->select;
    }

    return;
}

sub export_selection {
    my ( $self, $event ) = @_;
    my $src = $self->selected_text;

    _export( $self, $src );
    return;
}

sub export_document {
    my ( $self, $event ) = @_;

    my $doc = $self->selected_document;
    my $src = $doc->text_get;

    _export( $self, $src );
    return;
}


=head1 INSTALLATION

You can install this module like any other Perl module and it will
become available in your Padre editor. However, you can also
choose to install it into your user's Padre configuration directory only:

=over 4

=item * Install the prerequisite modules.

=item * perl Makefile.PL

=item * make

=item * make installplugin

=back

This will install the plugin as PerlTidy.par into your user's ~/.padre/plugins
directory.

Similarly, "make plugin" will just create the PerlTidy.par which you can
then copy manually.

=head1 AUTHOR

Brian Cassidy E<lt>bricas@cpan.orgE<gt>

Patrick Donelan

=head1 COPYRIGHT AND LICENSE

Copyright 2008 by Patrick Donelan, Brian Cassidy

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut

1;
