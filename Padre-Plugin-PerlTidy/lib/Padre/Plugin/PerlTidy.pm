package Padre::Plugin::PerlTidy;

=pod

=head1 NAME

Padre::Plugin::PerlTidy - Format perl files using Perl::Tidy

=head1 SYNOPIS

This is a simple plugin to run Perl::Tidy on your source code.

Currently there are no customisable options (since the Padre plugin system
doesn't support that yet) - however Perl::Tidy will use your normal .perltidyrc 
file if it exists (see Perl::Tidy documentation).

=cut

use 5.008001;
use strict;
use warnings;
use Padre::Current ();
use Padre::Wx      ();
use Padre::Plugin  ();
use constant { SELECTIONSIZE => 40, };  # this constant is used when storing
                                        # and restoring the cursor position.
                                        # Keep it small to limit resource use.
our $VERSION = '0.09';
our @ISA     = 'Padre::Plugin';

sub padre_interfaces {
    return 'Padre::Plugin' => '0.43',
        'Padre::Config'    => '0.54';
}

sub plugin_name {
    Wx::gettext( 'Perl Tidy' );
}

sub menu_plugins_simple {
    my $self = shift;
    return $self->plugin_name => [
        Wx::gettext( "Tidy the active document\tAlt+Shift+F" ) =>
            \&tidy_document,
        Wx::gettext( "Tidy the selected text\tAlt+Shift+G" ) =>
            \&tidy_selection,
        Wx::gettext( 'Export active document to HTML file' ) =>
            \&export_document,
        Wx::gettext( 'Export selected text to HTML file' ) =>
            \&export_selection,
    ];
}

sub _tidy {
    my ( $main, $src ) = @_;

    require Perl::Tidy;

    return unless defined $src;

    my $doc = $main->current->document;

    if ( !$doc->isa( 'Padre::Document::Perl' ) ) {
        return Wx::MessageBox(
            Wx::gettext( 'Document is not a Perl document' ),
            Wx::gettext( 'Error' ),
            Wx::wxOK | Wx::wxCENTRE, $main
        );
    }

    my ( $output, $error );
    my %tidyargs = (
        argv        => \'-nse -nst',
        source      => \$src,
        destination => \$output,
        errorfile   => \$error,
    );

    if ( my $tidyrc = $doc->project->config->config_perltidy ) {
        $tidyargs{ perltidyrc } = $tidyrc;
        Padre::Current->main->output->AppendText(
            "Perl\::Tidy running with project-specific configuration $tidyrc\n"
        );
    }
    else {
        Padre::Current->main->output->AppendText(
            "Perl\::Tidy running with default or user configuration\n" );
    }

    # TODO: suppress the senseless warning from PerlTidy
    eval { Perl::Tidy::perltidy( %tidyargs ); };

    if ( $@ ) {
        my $error_string = $@;
        Wx::MessageBox(
            $error_string,
            Wx::gettext( "PerlTidy Error" ),
            Wx::wxOK | Wx::wxCENTRE, $main
        );
        return;
    }

    if ( defined $error ) {
        my $width = length( $doc->filename ) + 2;
        Padre::Current->main->output->AppendText( "\n\n"
                . "-" x $width . "\n"
                . $doc->filename . "\n"
                . "-" x $width
                . "\n" );
        Padre::Current->main->output->AppendText( "$error\n" );
        Padre::Current->main->show_output( 1 );
    }
    return $output;
}

sub tidy_selection {
    my ( $main, $event ) = @_;
    my $src = $main->current->text;

    my $newtext = _tidy( $main, $src );

    return unless defined $newtext && length $newtext;

    $newtext =~ s{\n$}{};

    my $editor = $main->current->editor;
    $editor->ReplaceSelection( $newtext );
}

sub tidy_document {
    my ( $main, $event ) = @_;

    my $doc = $main->current->document;
    my $src = $doc->text_get;

    my $newtext = _tidy( $main, $src );

    return unless defined $newtext && length $newtext;

    my ( $regex, $start ) = _store_cursor_position( $main );
    $doc->text_set( $newtext );
    _restore_cursor_position( $main, $regex, $start );
}

sub _get_filename {
    my $main = shift;

    my $doc         = $main->current->document or return;
    my $current     = $doc->filename;
    my $default_dir = '';

    if ( defined $current ) {
        require File::Basename;
        $default_dir = File::Basename::dirname( $current );
    }

    require File::Spec;

    while ( 1 ) {
        my $dialog = Wx::FileDialog->new(
            $main, Wx::gettext( "Save file as..." ),
            $default_dir, $doc->filename . '.html',
            "*.*", Wx::wxFD_SAVE,
        );
        if ( $dialog->ShowModal == Wx::wxID_CANCEL ) {
            return;
        }
        my $filename = $dialog->GetFilename;
        $default_dir = $dialog->GetDirectory;
        my $path = File::Spec->catfile( $default_dir, $filename );
        if ( -e $path ) {
            my $res = Wx::MessageBox(
                Wx::gettext( "File already exists. Overwrite it?" ),
                Wx::gettext( "Exist" ),
                Wx::wxYES_NO, $main,
            );
            if ( $res == Wx::wxYES ) {
                return $path;
            }
        }
        else {
            return $path;
        }
    }
}

sub _export {
    my ( $main, $src ) = @_;

    require Perl::Tidy;

    return unless defined $src;

    my $doc = $main->current->document;

    if ( !$doc->isa( 'Padre::Document::Perl' ) ) {
        return Wx::MessageBox(
            Wx::gettext( 'Document is not a Perl document' ),
            Wx::gettext( 'Error' ),
            Wx::wxOK | Wx::wxCENTRE, $main
        );
    }

    my $filename = _get_filename( $main );

    return unless defined $filename;

    my ( $output, $error );
    my %tidyargs = (
        argv        => \'-html -nnn -nse -nst',
        source      => \$src,
        destination => $filename,
        errorfile   => \$error,
    );

    if ( my $tidyrc = $doc->project->config->config_perltidy ) {
        $tidyargs{ perltidyrc } = $tidyrc;
        Padre::Current->main->output->AppendText(
            "Perl\::Tidy running with project-specific configuration $tidyrc\n"
        );
    }

    else {
        Padre::Current->main->output->AppendText(
            "Perl::Tidy running with default or user configuration\n" );
    }

    # TODO: suppress the senseless warning from PerlTidy
    eval { Perl::Tidy::perltidy( %tidyargs ); };

    if ( $@ ) {
        my $error_string = $@;
        Wx::MessageBox(
            $error_string,
            Wx::gettext( 'PerlTidy Error' ),
            Wx::wxOK | Wx::wxCENTRE, $main
        );
        return;
    }

    if ( defined $error ) {
        my $width = length( $doc->filename ) + 2;
        my $main  = Padre::Current->main;
        $main->output->AppendText( "\n\n"
                . "-" x $width . "\n"
                . $doc->filename . "\n"
                . "-" x $width
                . "\n" );
        $main->output->AppendText( "$error\n" );
        $main->show_output( 1 );
    }

    return;
}

sub export_selection {
    my ( $main, $event ) = @_;
    my $src = $main->current->text;

    _export( $main, $src );
    return;
}

sub export_document {
    my ( $main, $event ) = @_;

    my $doc = $main->current->document;
    my $src = $doc->text_get;

    _export( $main, $src );
    return;
}

sub _restore_cursor_position {

    # parameter: $main, compiled regex
    my ( $main, $regex, $start ) = @_;
    my $doc    = $main->current->document;
    my $editor = $doc->editor;
    my $text   = $editor->GetTextRange(
        ( $start - SELECTIONSIZE ) > 0 ? $start - SELECTIONSIZE
        : 0,
        ( $start + SELECTIONSIZE < $editor->GetLength() )
        ? $start + SELECTIONSIZE
        : $editor->GetLength()
    );
    eval {
        if ( $text =~ /($regex)/ )
        {
            my $pos = $start + length $1;
            $editor->SetCurrentPos( $pos );
            $editor->SetSelection( $pos, $pos );
        }
    };
    $editor->goto_line_centerize( $editor->GetCurrentLine );
    return;
}

sub _store_cursor_position {

    # parameter: $main
    # returns: compiled regex, start position
    # compiled regex is /^./ if no valid regex can be reconstructed.
    my $main   = shift;
    my $doc    = $main->current->document;
    my $editor = $doc->editor;
    my $pos    = $editor->GetCurrentPos;
    my $start;

    if ( ( $pos - SELECTIONSIZE ) > 0 ) {
        $start = $pos - SELECTIONSIZE;
    }
    else {
        $start = 0;
    }
    my $prefix = $editor->GetTextRange( $start, $pos );
    my $regex;
    eval {
        $prefix =~ s/(\W)/\\$1/gm;    # Escape non-word chars
        $prefix
            =~ s/(\\\s+)/(\\s+|\\r*\\n)*/gm; # Replace whitespace by regex \s+
        $regex = qr{$prefix};
    };
    if ( $@ ) {
        $regex = qw{^.};
        print STDERR @_;
    }
    return ( $regex, $start );
}

1;

=pod

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

=head1 METHODS

=head2 padre_interfaces

Indicates our compatibility with Padre.

=head2 plugin_name

A simple accessor for the name of the plugin.

=head2 menu_plugins_simple

Menu items for this plugin.

=head2 tidy_document

Runs Perl::Tidy on the current document.

=head2 export_document

Export the current document as html.

=head2 tidy_selection

Runs Perl::Tidy on the current code selection.

=head2 export_selection

Export the current code selection as html.

=head1 AUTHOR

Brian Cassidy E<lt>bricas@cpan.orgE<gt>

Patrick Donelan

=head1 COPYRIGHT AND LICENSE

Copyright 2008-2010 by Patrick Donelan, Brian Cassidy

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
