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

# exports and version
our $VERSION = '0.026';
our @EXPORT_OK = qw(plugin_config);

use IPC::Run3;
use URI::Escape;
use URI::file;
use Readonly;

use Padre::Wx ();
use base 'Padre::Plugin';

# constants for html exporting
Readonly my $FULL_HTML    => 'full_html';
Readonly my $SIMPLE_HTML  => 'simple_html';
Readonly my $SNIPPET_HTML => 'snippet_html';

# static field to contain reference to current plugin configuration
my $config;

sub plugin_config {
    return $config;
}

sub padre_interfaces {
    return 'Padre::Plugin'         => 0.26,
}

# called when the plugin is enabled
sub plugin_enable {
    my $self = shift;

    # Read the plugin configuration, and create it if it is not there
    $config = $self->config_read;
    if(! $config) {
        # no configuration, let us write some defaults
        $config = {p6_highlight => 0};
        $self->config_write($config);
    }

    # let us parse some S29-functions.pod documentation (safely)
    eval {
        $self->build_perl6_doc;
    };
    warn $@ if $@;
    return 1;
}

sub menu_plugins {
    my $self        = shift;
    my $main_window = shift;

    # Create a simple menu with a single About entry
    $self->{menu} = Wx::Menu->new;

    # Perl6 S29 documentation
    Wx::Event::EVT_MENU(
        $main_window,
        $self->{menu}->Append( -1, "Show Perl6 Help\tF2", ),
        sub { $self->show_perl6_doc; },
    );

    $self->{menu}->AppendSeparator;

    # Manual Perl6 syntax highlighting
    Wx::Event::EVT_MENU(
        $main_window,
        $self->{menu}->Append( -1, "Refresh Perl6 Coloring\tF6", ),
        sub { $self->highlight; },
    );

    # Toggle Auto Perl6 syntax highlighting
    $self->{p6_highlight} =
        $self->{menu}->AppendCheckItem( -1, "Toggle Auto Perl6 Coloring",);
    Wx::Event::EVT_MENU(
        $main_window,
        $self->{p6_highlight},
        sub { $self->toggle_highlight; }
    );
    $self->{p6_highlight}->Check($config->{p6_highlight} ? 1 : 0);

    $self->{menu}->AppendSeparator;

    # Export into HTML
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

    # Cleanup STD.pm lex cache
    Wx::Event::EVT_MENU(
        $main_window,
        $self->{menu}->Append( -1, "Cleanup STD.pm Lex Cache", ),
        sub { $self->cleanup_std_lex_cache; },
    );

    $self->{menu}->AppendSeparator;

    # the famous about menu item...
    Wx::Event::EVT_MENU(
        $main_window,
        $self->{menu}->Append( -1, 'About', ),
        sub { $self->show_about },
    );

    # Return our plugin with its label
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
        "Perl6 syntax highlighting that is based on\n" .
        "Syntax::Highlight::Perl6\n"
    );
    $about->SetVersion($VERSION);
    Wx::AboutBox( $about );
    return;
}

#
# Cleans up STD lex cache after confirming with the user
#
sub cleanup_std_lex_cache {
    my $self = shift;

    my $main   = $self->main;

    my $LEX_STD_DIR = 'lex/STD';
    if(! -d $LEX_STD_DIR) {
        Wx::MessageBox(
            'Cannot find STD.pm lex cache',
            'Error',
            Wx::wxOK,
            $main,
        );
        return;
    }


    #find files in lex cache along with its total size;
    use File::Find;
    our @files_to_delete = ();
    my $lex_cache_size = 0;
    find(sub {
        my $file = $_;
        if(-f $file) {
            $lex_cache_size += -s $file;
            push @files_to_delete, $File::Find::name;
         }
    }, $LEX_STD_DIR);
    $lex_cache_size = sprintf("%0.3f", $lex_cache_size / (1024 * 1024));

    # ask the user if he/she wants to open it in the default browser
    my $num_files_to_delete = scalar @files_to_delete;
    if($num_files_to_delete > 0) {
        my $ret = Wx::MessageBox(
            "STD.pm lex cache has $num_files_to_delete file(s) and $lex_cache_size MB.\n" .
            "Do you want to clean it up now?",
            "Confirmation",
            Wx::wxYES_NO|Wx::wxCENTRE,
            $main,
        );
        if ( $ret == Wx::wxYES ) {
            #clean it up...
            my $deleted_count = unlink @files_to_delete;
            Wx::MessageBox(
                "STD.pm lex cache should be clean now.\n" .
                "Deleted $deleted_count out of $num_files_to_delete file(s).",
                'Information',
                Wx::wxOK,
                $main,
            );
        }
    } else {
        Wx::MessageBox(
            'STD.pm lex cache is already clean.',
            'Information',
            Wx::wxOK,
            $main,
        );
    }

    return;
}

#
# Original code idea from masak++ (http://use.perl.org/~masak/journal/38212)
#
sub build_perl6_doc {
    my $self = shift;

    # open the S29 file
    my $s29_file = File::Spec->join(File::Basename::dirname(__FILE__), '../Task/S29-functions.pod');
    my $S29 = IO::File->new(Cwd::realpath($s29_file))
                or croak "Cannot open '$s29_file' $!";

    # read until you find 'Function Packages'
    until (<$S29> =~ /Function Packages/) {}

    # parse the rest of S29 looking for Perl6 function documentation
    $self->{perl6_functions} = ();
    my $function_name = undef;
    while (my $line = <$S29>) {
        if ($line =~ /^=(\S+) (.*)/x) {
            if ($1 eq 'item') {
                # Found Perl6 function name
                $function_name = $2;
                $function_name =~ s/^\s+//;
            } else {
                $function_name = undef;
            }
        } elsif($function_name) {
            # Adding documentation to the function name
            $self->{perl6_functions}{$function_name} .= $line;
        }
    }

    # trim blank lines at the beginning and the end
    foreach my $function_name (keys %{$self->{perl6_functions}}) {
        my $docs = $self->{perl6_functions}{$function_name};
        $docs =~ s/^(\s|\n)+//g;
        $docs =~ s/(\s|\n)+$//g;
        $self->{perl6_functions}{$function_name} = $docs;
    }

}

sub show_perl6_doc {
    my $self = shift;
    my $main   = $self->main;

    if(! $self->{perl6_functions}) {
        Wx::MessageBox(
            'Perl6 S29 docs are not available',
            'Error',
            Wx::wxOK,
            $main,
        );
        return;
    }

    # find the word under the current cursor position
    my $doc = Padre::Current->document;
    if($doc) {
        # make sure it is a Perl6 document
        if($doc->get_mimetype ne q{application/x-perl6}) {
            Wx::MessageBox(
                'Not a Perl6 file',
                'Operation cancelled',
                Wx::wxOK,
                $main,
            );
            return;
        }

        my $editor = $doc->editor;
        my $lineno = $editor->GetCurrentLine();
        my $line = $editor->GetLine($lineno);
        my $current_pos = $editor->GetCurrentPos() - $editor->PositionFromLine($lineno);
        my $current_word = '';
        while( $line =~ m/\G.*?([[:alnum:]]+)/g ) {
            if(pos($line) >= $current_pos) {
                $current_word = $1;
                last;
            }
        }
        if($current_word =~ /^.*?(\w+)/) {
            my $function_name = $1;
            say "Looking up: " . $function_name;
            my $function_doc = $self->{perl6_functions}{$function_name};
            if($function_doc) {
                #launch default browser to see the S29 function documentation
                Wx::LaunchDefaultBrowser(
                    q{http://perlcabal.org/syn/S29.html#} .
                    URI::Escape::uri_escape_utf8($function_name));
            }
        }

    }
}

sub toggle_highlight {
    my $self = shift;
    if(! defined $self->{p6_highlight}) {
        return;
    }
    $config->{p6_highlight} = $self->{p6_highlight}->IsChecked ? 1 : 0;
    $self->config_write($config);
    if($config->{p6_highlight}) {
        $self->highlight;
    }
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

    my $main   = $self->main;

    my $doc = Padre::Current->document;
    if(!defined $doc) {
        return;
    }
    if($doc->get_mimetype ne q{application/x-perl6}) {
        Wx::MessageBox(
            'Not a Perl6 file',
            'Export cancelled',
            Wx::wxOK,
            $main,
        );
        return;
    }

    my $text = $self->text_with_one_nl($doc);

    # construct the command
    my @cmd = ( Padre::Util::WIN32 ? 'hilitep6.bat' : 'hilitep6' );

    my $html;
    given($type) {
        when ($FULL_HTML) { push @cmd, '--full-html=-'; }
        when ($SIMPLE_HTML) { push @cmd, '--simple-html=-'; }
        when ($SNIPPET_HTML) { push @cmd, '--snippet-html=-' }
        default {
            # default is full html
            push @cmd, '--full-html=-';
        }
    }

    my ($out, $err) = ('',undef);
    run3(\@cmd, \$text, \$out, \$err, {
          'binmode_stdin' => ':utf8',
          'binmode_stdout' => 1,
    });
    if($err) {
        # remove ANSI color escape sequences...
        $err =~ s/\033\[(\d+)(?:;(\d+)(?:;(\d+))?)?m//g;
        Wx::MessageBox(
            qq{STD.pm warning/error:\n$err},
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
