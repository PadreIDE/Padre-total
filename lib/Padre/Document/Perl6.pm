package Padre::Document::Perl6;

use 5.010;
use strict;
use warnings;
use feature qw(say);
use English '-no_match_vars';  # Avoids regex performance penalty
use Padre::Document ();

use Benchmark;
use Syntax::Highlight::Perl6;

our $VERSION = '0.22';
our @ISA     = 'Padre::Document';

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

# Naive way to parse and colorize perl6 files
sub colorize {
    my ($self, $first) = @_;

    my $editor = $self->editor;
    my $text   = $self->text_with_one_nl;

    my $t0 = Benchmark->new;
    my $p = Syntax::Highlight::Perl6->new(
        text => $text,
    );

    my @tokens;
    eval { @tokens = $p->tokens;   1; };
    $self->{issues} = [];
    if($EVAL_ERROR) {
        say "Parsing error, bye bye ->colorize " . $EVAL_ERROR;
        my @errors = split /\n/, $EVAL_ERROR;
        my $lineno = undef;
        for my $error (@errors) {
            if($error =~ /line (\d+):$/) {
                $lineno = $1;
            }
            if($lineno) {
                push @{$self->{issues}}, { line => $lineno, msg => $error, severity => 'E', };
            }
        }
        return;
    } 

    $self->remove_color;

    my %colors = (
        'comp_unit'  => Px::PADRE_BLUE,
        'scope_declarator' => Px::PADRE_RED,
        'routine_declarator' => Px::PADRE_RED,
        'regex_declarator' => Px::PADRE_RED,
        'package_declarator' => Px::PADRE_RED,
        'statement_control' => Px::PADRE_RED,
        'block' => Px::PADRE_BLACK,
        'regex_block' => Px::PADRE_BLACK,
        'noun' => Px::PADRE_BLACK,
        'sigil' => Px::PADRE_GREEN,
        'variable' => Px::PADRE_GREEN,
        'assertion' => Px::PADRE_GREEN,
        'quote' => Px::PADRE_MAGENTA,
        'number' => Px::PADRE_ORANGE,
        'infix' => Px::PADRE_DIM_GRAY,
        'methodop' => Px::PADRE_BLACK,
        'pod_comment' => Px::PADRE_GREEN,
        'param_var' => Px::PADRE_CRIMSON,
        '_scalar' => Px::PADRE_RED,
        '_array' => Px::PADRE_BROWN,
        '_hash' => Px::PADRE_ORANGE,
        '_comment' => Px::PADRE_GREEN,
    );

    for my $htoken (@tokens) {
        my %token = %{$htoken};
        my $color = $colors{ $token{rule} };
        if($color) {
              my $len = length $token{buffer};
              my $start = $token{last_pos} - $len;
              $editor->StartStyling($start, $color);
              $editor->SetStyling($len, $color);
        }
    }

      my $td = timediff(new Benchmark, $t0);
      say "->colorize took:" . timestr($td) ;
}

sub get_command {
    my $self     = shift;

    my $filename = $self->filename;

    if (not $ENV{PARROT_PATH}) {
        die "PARROT_PATH is not defined. Need to point to trunk of Parrot SVN checkout.\n";
    }
    my $parrot = File::Spec->catfile($ENV{PARROT_PATH}, 'parrot');
    if (not -x $parrot) {
        die "$parrot is not an executable.\n";
    }
    my $rakudo = File::Spec->catfile($ENV{PARROT_PATH}, 'languages', 'perl6', 'perl6.pbc');
    if (not -e $rakudo) {
        die "Cannot find Rakudo ($rakudo)\n";
    }

    return qq{"$parrot" "$rakudo" "$filename"};

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
        $self->{keywords} = YAML::Tiny::LoadFile(
            Padre::Util::sharefile( 'languages', 'perl6', 'perl6.yml' )
        );
    }
    return $self->{keywords};
}

sub comment_lines_str { return '#' }

1;

# Copyright 2008 Gabor Szabo.
# LICENSE
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl 5 itself.
