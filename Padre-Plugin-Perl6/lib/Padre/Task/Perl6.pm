package Padre::Task::Perl6;

use strict;
use warnings;
use base 'Padre::Task';

our $VERSION = '0.35';
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
		$doc->{tokens} = $self->{tokens};
    } else {
		$doc->{tokens} = [];
	}
	
	if($self->{issues}) {
        # pass errors/warnings to document...
        $doc->{issues} = $self->{issues};
    } else {
		$doc->{issues} = [];
	}
	
	$doc->check_syntax_in_background(force => 1);
	$doc->get_outline(force => 1);

    # finished here
    $thread_running = 0;

    return 1;
}

# Task thread subroutine
sub run {
    my $self = shift;

	# temporary file for the process STDIN
	require File::Temp;
	my $tmp_in = File::Temp->new( SUFFIX => '_p6_in.txt' );
	binmode $tmp_in, ':utf8';
	print $tmp_in $self->{text};
	delete $self->{text};
	close $tmp_in or warn "cannot close $tmp_in\n";

	# temporary file for the process STDOUT
	my $tmp_out = File::Temp->new( SUFFIX => '_p6_out.txt' );
	close $tmp_out or warn "cannot close $tmp_out\n";
	
	# temporary file for the process STDERR
	my $tmp_err = File::Temp->new( SUFFIX => '_p6_err.txt' );
	close $tmp_err or warn "cannot close $tmp_out\n";
	
    # construct the command
	require Cwd;
	require File::Basename;
	require File::Spec;
	my $cmd = Padre->perl_interpreter . " " .
		Cwd::realpath(File::Spec->join(File::Basename::dirname(__FILE__),'p6tokens.pl')) .
		" $tmp_in $tmp_out $tmp_err";
	
	# all this is needed to prevent win32 platforms from:
	# 1. popping out a command line on each run...
	# 2. STD.pm uses Storable 
	# 3. Padre TaskManager does not like tasks that do Storable operations...
	my $is_win32 = ($^O =~ /MSWin/);
	if($is_win32) {
		use Win32;
		use Win32::Process;

		sub print_error {
		   print Win32::FormatMessage(Win32::GetLastError());
		}

		my $p_obj;
		Win32::Process::Create($p_obj, Padre->perl_interpreter, $cmd, 0, DETACHED_PROCESS, '.') 
			or warn &print_error;
		$p_obj->Wait(INFINITE);
	} else {
		`$cmd`;
	}
		
	my ($out, $err);
	{
		local $/ = undef;   #enable localized slurp mode

		# slurp the process output...
		open CHLD_OUT, $tmp_out	or warn "Could not open $tmp_out";
		binmode CHLD_OUT;
		$out = <CHLD_OUT>;
		close CHLD_OUT or warn "Could not close $tmp_out\n";
		
		open CHLD_ERR, $tmp_err or warn "Cannot open $tmp_err\n";
		binmode CHLD_ERR, ':utf8';
		$err = <CHLD_ERR>;
		close CHLD_ERR or warn "Could not close $tmp_err\n";
	}
	
    if($err) {
        # remove ANSI color escape sequences...
        $err =~ s/\033\[\d+(?:;\d+(?:;\d+)?)?m//g;
        print qq{STD.pm warning/error:\n$err\n};
        my @messages = split /\n/, $err;
        my ($lineno, $severity);
		my $issues = [];
        for my $msg (@messages) {
			if($msg =~ /^\#\#\#\#\# PARSE FAILED \#\#\#\#\#/) {
				# the following lines are errors until we see the warnings section
				$severity = 'E';
			} elsif($msg =~ /^Potential difficulties/) {
				# all rest are warnings...
				$severity = 'W';
			} elsif($msg =~ /line (\d+):$/i) {
                #record the line number
                $lineno = $1;
            } 
            if($lineno) {
                push @{$issues}, { line => $lineno, msg => $msg, severity => $severity, };
            }
        }
        $self->{issues} = $issues;
    } 
	
	if($out) {
		eval {
			require Storable;
         	$self->{tokens} = Storable::thaw($out);
		};
		if ($@) {
			warn "Exception: $@";
		}
    }

    return 1;
};

1;
