package Padre::Document::Perl6;

use 5.010;
use strict;
use warnings;
use feature qw(say);
use English '-no_match_vars';  # Avoids regex performance penalty
use Padre::Document ();
use Padre::Task::Perl6 ();
use Readonly;

our $VERSION = '0.26';
our @ISA     = 'Padre::Document';

# max lines to display in a calltip
Readonly my $CALLTIP_DISPLAY_COUNT => 10;

sub text_with_one_nl {
    my $self = shift;
    my $text = $self->text_get;
    my $nlchar = "\n";
    if ( $self->get_newline_type eq 'WIN' ) {
        $nlchar = "\r\n";
    }
    elsif ( $self->get_newline_type eq 'MAC' ) {
        $nlchar = "\r";
    }
    $text =~ s/$nlchar/\n/g;
    return $text;
}

# a SLOW WAY to parse and colorize perl6 files
sub colorize {
    my $doc = shift;

    my $config = Padre::Plugin::Perl6::plugin_config;
    if($config->{p6_highlight} || $doc->{force_p6_highlight}) {
        # Create a coloring task and hand off to the task manager
        my $task = Padre::Task::Perl6->new(
            text => $doc->text_with_one_nl,
            editor => $doc->editor,
            document => $doc);
        $task->schedule();
    }
}

sub get_command {
    my $self     = shift;

    my $filename = $self->filename;

    if (not $ENV{RAKUDO_DIR}) {
    	my $main = Padre->ide->wx->main;
    	$main->error("RAKUDO_DIR is not defined. Need to point to the directory of the Rakudo checkout.");
    }
    my $perl6 = File::Spec->catfile($ENV{RAKUDO_DIR}, ($^O eq 'MSWin32') ? 'perl6.exe' : 'perl6');
    return qq{"$perl6" "$filename"};
}

# Checks the syntax of a Perl document.
# Documented in Padre::Document!
# Implemented as a task. See Padre::Task::SyntaxChecker::Perl6
sub check_syntax {
    my $self  = shift;
    my %args  = @ARG;
    $args{background} = 0;
    return $self->_check_syntax_internals(\%args);
}

sub check_syntax_in_background {
    my $self  = shift;
    my %args  = @ARG;
    $args{background} = 1;
    return $self->_check_syntax_internals(\%args);
}

sub _check_syntax_internals {
    my $self = shift;
    my $args  = shift;

    my $text = $self->text_with_one_nl;
    unless ( defined $text and $text ne '' ) {
        return [];
    }

    # Do we really need an update?
    require Digest::MD5;
    use Encode qw(encode_utf8);
    my $md5 = Digest::MD5::md5(encode_utf8($text));
    unless ( $args->{force} ) {
        if ( defined( $self->{last_checked_md5} )
             && $self->{last_checked_md5} eq $md5
        ) {
            return;
        }
    }
    $self->{last_checked_md5} = $md5;

    require Padre::Task::SyntaxChecker::Perl6;
    my $task = Padre::Task::SyntaxChecker::Perl6->new(
        notebook_page => $self->editor,
        text => $text,
        issues => $self->{issues},
        ( exists $args->{on_finish} ? (on_finish => $args->{on_finish}) : () ),
    );
    if ($args->{background}) {
        # asynchroneous execution (see on_finish hook)
        $task->schedule();
        return();
    }
    else {
        # serial execution, returning the result
        return() if $task->prepare() =~ /^break$/;
        $task->run();
        return $task->{syntax_check};
    }
    return;
}

sub keywords {
    my $self = shift;
    if (! defined $self->{keywords}) {
        #Get keywords from Plugin object
        my $manager = Padre->ide->plugin_manager;
        if($manager) {
            my $plugin = $manager->plugins->{'Perl6'};
            if($plugin) {
                my %perl6_functions = %{$plugin->object->{perl6_functions}};
                foreach my $function (keys %perl6_functions) {
                    my $docs = $perl6_functions{$function};
                    # limit calltip size to n-lines
                    my @lines = split /\n/, $docs;
                    if(scalar @lines > $CALLTIP_DISPLAY_COUNT) {
                        $docs = (join "\n", @lines[0..$CALLTIP_DISPLAY_COUNT-1]) .
                            "\n...";
                    }
                    $self->{keywords}->{$function} = {
                        'cmd' => $docs,
                        'exp' => '',
                    };
                }
             }
        }
    }
    return $self->{keywords};
}

sub comment_lines_str { return '#' }

1;

# Copyright 2008 Gabor Szabo.
# LICENSE
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl 5 itself.
