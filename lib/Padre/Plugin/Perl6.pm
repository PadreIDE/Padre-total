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

our $VERSION = '0.020';

use URI::file;
use Readonly;

use Padre::Wx ();
use base 'Padre::Plugin';

# constants for html exporting
Readonly my $FULL_HTML    => 'full_html';
Readonly my $SIMPLE_HTML  => 'simple_html';
Readonly my $SNIPPET_HTML => 'snippet_html';

sub padre_interfaces {
    return 'Padre::Plugin'         => 0.22,
}

sub menu_plugins {
    my $self        = shift;
    my $main_window = shift;

    # Create a simple menu with a single About entry
    $self->{menu} = Wx::Menu->new;

    # Manual Perl 6 syntax highlighting
    Wx::Event::EVT_MENU(
        $main_window,
        $self->{menu}->Append( -1, "Manual Perl 6 syntax highlighting\tCtrl-R", ),
        sub { $self->highlight(0); },
    );

    # Toggle Auto Perl 6 syntax highlighting
    $self->{p6_highlight} = 
        $self->{menu}->AppendCheckItem( -1, "Automatic Perl 6 syntax highlighting",);
    Wx::Event::EVT_MENU(
        $main_window,
        $self->{p6_highlight},
        sub { $self->toggle_highlight; }
    );
    my $config = Padre->ide->config;
    $self->{p6_highlight}->Check($config->{p6_highlight} ? 1 : 0);

    $self->{menu}->AppendSeparator;

    # export into HTML
    Wx::Event::EVT_MENU(
        $main_window,
        $self->{menu}->Append( -1, 'Export Full HTML', ),
        sub { $self->export_html($FULL_HTML); },
    );
    Wx::Event::EVT_MENU(
        $main_window,
        $self->{menu}->Append( -1, 'Export Simple HTML', ),
        sub { $self->export_html($SIMPLE_HTML); },
    );
    Wx::Event::EVT_MENU(
        $main_window,
        $self->{menu}->Append( -1, 'Export Snippet HTML', ),
        sub { $self->export_html($SNIPPET_HTML); },
    );

    $self->{menu}->AppendSeparator;

    # the famous about menu item...
    Wx::Event::EVT_MENU(
        $main_window,
        $self->{menu}->Append( -1, 'About', ),
        sub { $self->show_about },
    );

    # Return it and the label for our plugin
    return ( $self->plugin_name => $self->{menu} );
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

sub toggle_highlight {
    my $self = shift;
    if(! defined $self->{p6_highlight}) {
        return;
    }
    my $config = Padre->ide->config;
    if($config->{p6_highlight}) {
        $self->highlight;
    }
    $config->{p6_highlight} = $self->{p6_highlight}->IsChecked ? 1 : 0;
}

sub highlight {
    my $self = shift;
    my $doc = Padre::Current->document or return;
    
    if ($doc->can('colorize')) {
        my $text = $doc->text_get;
        $doc->{_text} = $text;
        $doc->{force_p6_highlight} = 1;
        $doc->colorize;
        $doc->{force_p6_highlight} = 0;
    }
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

    my $doc = Padre::Current->document;
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
