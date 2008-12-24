# Copyright 2008 Gabor Szabo.
# LICENSE
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl 5 itself.
package Padre::Plugin::Perl6;

use 5.010;
use strict;
use warnings;
use English;
use Carp;
use feature qw(say switch);
use IO::File;
use File::Temp;

our $VERSION = '0.012';

use URI::file;
use Syntax::Highlight::Perl6;
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
    my ($main) = @ARG;

    my $about = Wx::AboutDialogInfo->new;
    $about->SetName("Padre::Plugin::Perl6");
    $about->SetDescription(
        "Perl6 syntax highlighting that is based on\nSyntax::Highlight::Perl6\n"
    );
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
    my ($self, $type) = @ARG;

    my $doc = Padre::Documents->current;
    if(!defined $doc) {
        return;
    }
    if($doc->get_mimetype ne q{application/x-perl6}) {
		Wx::MessageBox(
			'Not a Perl 6 file',
			'Export cancelled',
			Wx::wxOK,
			Padre->ide->wx->main_window
		);
        return;
    }
    
    my $text = $self->text_with_one_nl($doc);
    my $p = Syntax::Highlight::Perl6->new(
        text => $text,
        inline_resources => 1,
    );

    my $html;
    eval {
        given($type) {
            when ($FULL_HTML) { $html = $p->full_html; }
            when ($SIMPLE_HTML) { $html = $p->simple_html; }
            when ($SNIPPET_HTML) { $html = $p->snippet_html; }
            default {
                croak "'$type' should full_html, simple_html or snippet_html";
            }
        }
        1;
    };

    if($EVAL_ERROR) {
		Wx::MessageBox(
			qq{STD.pm Parsing Error:\n$EVAL_ERROR},
			'Export cancelled',
			Wx::wxOK,
			Padre->ide->wx->main_window
		);
        say "\nSTD.pm Parsing error\n" . $EVAL_ERROR;
        return;
    }

    # create a temporary HTML file
    my $tmp = File::Temp->new(SUFFIX => '.html');
    $tmp->unlink_on_destroy(0);
    my $filename = $tmp->filename;
    print $tmp $html;
    close $tmp
        or croak "Could not close $filename";

    # try to open the HTML file
    my $main   = Padre->ide->wx->main_window;
    $main->setup_editor($filename);

    # launch the HTML file in your default browser
    my $file_url = URI::file->new($filename);
    Wx::LaunchDefaultBrowser($file_url);

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
