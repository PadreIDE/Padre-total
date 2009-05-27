package Padre::Plugin::PerlTidy;

use 5.008001;
use strict;
use warnings;

use base 'Padre::Plugin';

use Padre::Wx   ();
use Padre::Util ('_T');

our $VERSION = '0.06';

=pod

=head1 NAME

Padre::Plugin::PerlTidy - Format perl files using Perl::Tidy

=head1 SYNOPIS

This is a simple plugin to run Perl::Tidy on your source code.

Currently there are no customisable options (since the Padre plugin system
doesn't support that yet) - however Perl::Tidy will use your normal .perltidyrc 
file if it exists (see Perl::Tidy documentation).

=cut

sub padre_interfaces {
    'Padre::Plugin' => '0.26',
      ;
}

sub menu_plugins_simple {
    PerlTidy => [
        _T("Tidy the active document\tAlt+Shift+F") => \&tidy_document,
        _T("Tidy the selected text\tAlt+Shift+G")   => \&tidy_selection,
        _T('Export active document to HTML file')   => \&export_document,
        _T('Export selected text to HTML file')     => \&export_selection,
    ];
}

sub _tidy {
    my ( $main, $src ) = @_;

    require Perl::Tidy;

    return unless defined $src;

    my $doc = $main->current->document;

    if ( !$doc->isa('Padre::Document::Perl') ) {
        return Wx::MessageBox( _T('Document is not a Perl document'),
            _T('Error'), Wx::wxOK | Wx::wxCENTRE, $main );
    }

    my ( $output, $error );

    # TODO: suppress the senseless warning from PerlTidy
    eval {
        my $argv = '';
        Perl::Tidy::perltidy(
            argv        => \$argv,
            source      => \$src,
            destination => \$output,
            errorfile   => \$error,
        );
    };

    if ($@) {
        my $error_string = $@;
        Wx::MessageBox( $error_string, _T("PerlTidy Error"),
            Wx::wxOK | Wx::wxCENTRE, $main );
        return;
    }

    if ( defined $error ) {
        my $width = length( $doc->filename ) + 2;
        Padre::Current->main->output->AppendText( "\n\n"
              . "-" x $width . "\n"
              . $doc->filename . "\n"
              . "-" x $width
              . "\n" );
        Padre::Current->main->output->AppendText("$error\n");
        Padre::Current->main->show_output(1);
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
    $editor->ReplaceSelection($newtext);
}

sub tidy_document {
    my ( $main, $event ) = @_;

    my $doc = $main->current->document;
    my $src = $doc->text_get;

    my $newtext = _tidy( $main, $src );

    return unless defined $newtext && length $newtext;

    my $regex = _store_cursor_position($main);
    $doc->text_set($newtext);
    _restore_cursor_position( $main, $regex );
}

sub _get_filename {
    my $main = shift;

    my $doc         = $main->current->document or return;
    my $current     = $doc->filename;
    my $default_dir = '';

    if ( defined $current ) {
        require File::Basename;
        $default_dir = File::Basename::dirname($current);
    }

    require File::Spec;

    while (1) {
        my $dialog =
          Wx::FileDialog->new( $main, _T("Save file as..."), $default_dir,
            $doc->filename . '.html',
            "*.*", Wx::wxFD_SAVE, );
        if ( $dialog->ShowModal == Wx::wxID_CANCEL ) {
            return;
        }
        my $filename = $dialog->GetFilename;
        $default_dir = $dialog->GetDirectory;
        my $path = File::Spec->catfile( $default_dir, $filename );
        if ( -e $path ) {
            my $res = Wx::MessageBox( _T("File already exists. Overwrite it?"),
                _T("Exist"), Wx::wxYES_NO, $main, );
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

    if ( !$doc->isa('Padre::Document::Perl') ) {
        return Wx::MessageBox( _T('Document is not a Perl document'),
            _T('Error'), Wx::wxOK | Wx::wxCENTRE, $main );
    }

    my $filename = _get_filename($main);

    return unless defined $filename;

    my ( $output, $error );

    # TODO: suppress the senseless warning from PerlTidy
    eval {
        my $argv = '-html -nnn';
        Perl::Tidy::perltidy(
            argv        => \$argv,
            source      => \$src,
            destination => $filename,
            errorfile   => \$error,
        );
    };

    if ($@) {
        my $error_string = $@;
        Wx::MessageBox( $error_string, _T('PerlTidy Error'),
            Wx::wxOK | Wx::wxCENTRE, $main );
        return;
    }

    if ( defined $error ) {
        my $width = length( $doc->filename ) + 2;
        Padre::Current->main->output->AppendText( "\n\n"
              . "-" x $width . "\n"
              . $doc->filename . "\n"
              . "-" x $width
              . "\n" );
        Padre::Current->main->output->AppendText("$error\n");
        Padre::Current->main->show_output(1);
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
    my ( $main, $regex, $regex_pos ) = @_;
    my $doc    = $main->current->document;
    my $editor = $doc->editor;
    my $text   = $editor->GetTextRange( 0, $editor->GetLength() );
    if ( $text =~ /($regex)/ ) {
        my $pos = length $1;
        $editor->SetCurrentPos($pos);
        $editor->SetSelection( $pos, $pos );
    }
    else { print "No party!\n"; print $regex; }
    return;
}

sub _store_cursor_position {

    # parameter: $main
    # returns: compiled regex
    # compiled regex is /^./ if no valid regex can be reconstructed.
    my $main   = shift;
    my $doc    = $main->current->document;
    my $editor = $doc->editor;
    my $pos    = $editor->GetCurrentPos;

  # A smaller selection to save memory (disabled)
  #    my $sel_width = 200;  # chars before and after cursor
  #    my $pre_start;
  #
  #    if ( ( $pos - $sel_width ) > 0 ) {
  #        $pre_start = $pos - $sel_width;
  #    }
  #    else {
  #        $pre_start = 0;
  #    }
  #    my $prefix = $editor->GetTextRange( $pre_start, $pos );
    my $prefix = $editor->GetTextRange( 0, $pos );
    my $regex;
    eval {
        $prefix =~ s/(\W)/\\$1/gm;    # Escape non-word chars
        $prefix =~
          s/(\\\s+)/(\\s+|\\r*\\n)*/gm;    # Replace whitespace by regex \s+
        $regex = qr{$prefix};
    };
    if ($@) {
        $regex = qw{^.};
        print @_;
    }
    return $regex;
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

=head1 AUTHOR

Brian Cassidy E<lt>bricas@cpan.orgE<gt>

Patrick Donelan

=head1 COPYRIGHT AND LICENSE

Copyright 2008-2009 by Patrick Donelan, Brian Cassidy

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
