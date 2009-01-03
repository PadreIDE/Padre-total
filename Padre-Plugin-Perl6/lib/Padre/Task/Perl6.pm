package Padre::Task::Perl6;

use strict;
use warnings;
use feature 'say';
use base 'Padre::Task';

use Carp;
use IPC::Run;
use Storable;
use File::Basename;
use File::Spec;
use Cwd;

our $thread_running = 0;

# This is run in the main thread before being handed
# off to a worker (background) thread. The Wx GUI can be
# polled for information here.
# If you don't need it, just inherit this default no-op.
sub prepare {
    my $self = shift;

    # put editor into main-thread-only storage
    $self->{main_thread_only} ||= {};
    my $document = $self->{document} || $self->{main_thread_only}{document};
    my $editor = $self->{editor} || $self->{main_thread_only}{editor};
    delete $self->{document};
    delete $self->{editor};
    $self->{main_thread_only}{document} = $document;
    $self->{main_thread_only}{editor} = $editor;

    # assign a place in the work queue
    if($thread_running) {
	return "break";
    }
    $thread_running = 1;
    return 1;
}

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

# This is run in the main thread after the task is done.
# It can update the GUI and do cleanup.
# You don't have to implement this if you don't need it.
sub finish {
    my $self = shift;
    my $mainwindow = shift;

    my $doc = $self->{main_thread_only}{document};
    my $editor = $self->{main_thread_only}{editor};
    if($self->{tokens}) {
	$doc->remove_color;
	my @tokens = @{$self->{tokens}};
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
	$doc->{issues} = [];
    } elsif($self->{issues}) {
	# pass errors/warnings to document...
	$doc->{issues} = $self->{issues};
    }
    # cleanup!

    # finished here
    $thread_running = 0;

    return 1;
}

# Task thread subroutine
sub run {
    my $self = shift;
    my $text = $self->{text};
    delete $self->{text};

    # construct the command
    my @cmd = ( Padre->perl_interpreter,
	Cwd::realpath(File::Spec->join(File::Basename::dirname(__FILE__),'p6tokens.pl')));
    say "Running @cmd";

    my ($in, $out, $err) = ($text,'',undef);
    my $h = IPC::Run::run(\@cmd, \$in, \$out, \$err);
    if($err) {
	my @messages = split /\n/, $err;
	my ($lineno,$severity);
	my $issues = [];
	for my $msg (@messages) {
	    if($msg =~ /error\s.+?line (\d+):$/i) {
		#an error
		($lineno,$severity) = ($1, 'E');
	    } elsif($msg =~ /line (\d+):$/i) {
		#a warning
		($lineno,$severity) = ($1, 'W');
	    }
	    if($lineno) {
		push @{$issues}, { line => $lineno, msg => $msg, severity => $severity, };
	    }
	}
	$self->{issues} = $issues;
    } else {
        $self->{tokens} = Storable::thaw($out);
    }

    return 1;
};

1;
