# Copyright 2008 Gabor Szabo.
# LICENSE
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl 5 itself.
package Padre::Plugin::Perl6;

use 5.010;
use strict;
use warnings;
use Carp;
use feature qw(say switch);
use IO::File;
use File::Temp;
use IPC::Run;

our $VERSION = '0.018';

use URI::file;
use Readonly;

use Padre::Wx ();
use base 'Padre::Plugin';

Readonly my $FULL_HTML    => 'full_html';
Readonly my $SIMPLE_HTML  => 'simple_html';
Readonly my $SNIPPET_HTML => 'snippet_html';

sub padre_interfaces {
    return 'Padre::Plugin'         => 0.20,
}


sub menu_plugins_simple {
    my $self = shift;
    return 'Perl 6' => [
        'Export Full HTML' => sub { $self->export_html($FULL_HTML); },
        'Export Simple HTML' => sub { $self->export_html($SIMPLE_HTML); },
        'Export Snippet HTML' => sub { $self->export_html($SNIPPET_HTML); },
        '---' => undef,
        'About' => sub { $self->show_about },
    ];
}

sub registered_documents {
    return 'application/x-perl6'    => 'Padre::Document::Perl6',
}


sub show_about {
    my ($main) = @_;

    my $about = Wx::AboutDialogInfo->new;
    $about->SetName("Padre::Plugin::Perl6");
    $about->SetDescription(
        "Perl6 syntax highlighting that is based on\nSyntax::Highlight::Perl6\n"
    );
	$about->SetVersion($VERSION);
    Wx::AboutBox( $about );
    return;
}

sub text_with_one_nl {
    my $self = shift;
    my $doc = shift;
    my $text = $doc->text_get // '';
    
    my $nlchar = "\n";
    if ( $doc->get_newline_type eq 'WIN' ) {
        $nlchar = "\r\n";
    }
    elsif ( $doc->get_newline_type eq 'MAC' ) {
        $nlchar = "\r";
    }
    $text =~ s/$nlchar/\n/g;
    return $text;
}

sub export_html {
    my ($self, $type) = @_;

    my $main   = Padre->ide->wx->main_window;

    my $doc = Padre::Documents->current;
    if(!defined $doc) {
        return;
    }
    if($doc->get_mimetype ne q{application/x-perl6}) {
        Wx::MessageBox(
            'Not a Perl 6 file',
            'Export cancelled',
            Wx::wxOK,
            $main,
        );
        return;
    }
    
    my $text = $self->text_with_one_nl($doc);

    # construct the command
    my @cmd = ( 'hilitep6' );
    say "Running @cmd";

    my $html;
    eval {
        given($type) {
            when ($FULL_HTML) { push @cmd, '--full-html=-'; }
            when ($SIMPLE_HTML) { push @cmd, '--simple-html=-'; }
            when ($SNIPPET_HTML) { push @cmd, '--snippet-html=-' }
            default {
                croak "'$type' should full_html, simple_html or snippet_html";
            }
        }
        1;
    };

    my ($in, $out, $err) = ($text,'',undef);
    my $h = IPC::Run::run(\@cmd, \$in, \$out, \$err);
    if($err) {
        Wx::MessageBox(
            qq{STD.pm Parsing Error:\n$err},
            'Export cancelled',
            Wx::wxOK,
            $main,
        );
        say "\nSTD.pm Parsing error\n" . $err;
        return;
    } else {
        $html = $out;
    }

    # create a temporary HTML file
    my $tmp = File::Temp->new(SUFFIX => '.html');
    $tmp->unlink_on_destroy(0);
    my $filename = $tmp->filename;
    print $tmp $html;
    close $tmp
        or croak "Could not close $filename";

    # try to open the HTML file
    $main->setup_editor($filename);

    # ask the user if he/she wants to open it in the default browser
    my $ret = Wx::MessageBox(
        "Saved to $filename. Do you want to open it now?",
        "Done",
        Wx::wxYES_NO|Wx::wxCENTRE,
        $main,
    );
    if ( $ret == Wx::wxYES ) {
        # launch the HTML file in your default browser
        my $file_url = URI::file->new($filename);
        Wx::LaunchDefaultBrowser($file_url);
    }

    return;
}


1;

__END__

=head1 NAME

Padre::Plugin::Perl6 - Padre plugin for Perl6

=head1 SYNOPSIS

After installation when you run Padre there should be a menu option Plugins/Perl6.

=head1 AUTHOR

Ahmad M. Zawawi, C<< <ahmad.zawawi at gmail.com> >>

Gabor Szabo L<http://www.szabgab.com/>

=head1 COPYRIGHT

Copyright 2008 Gabor Szabo. L<http://www.szabgab.com/>

=head1 LICENSE

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl 5 itself.
