use strict;
use warnings;

use t::lib::Debugger;

my ($dir, $pid) = start_script('t/eg/04-fib.pl');

require Test::More;
import Test::More;
require Test::Deep;
import Test::Deep;

plan(tests => 38);
our $TODO;

use Data::Dumper qw(Dumper);

my $debugger = start_debugger();

{
    my $out = $debugger->get;
 
# Loading DB routines from perl5db.pl version 1.28
# Editor support available.
# 
# Enter h or `h h' for help, or `man perldebug' for more help.
# 
# main::(t/eg/01-add.pl:4):	$| = 1;
#   DB<1> 

    like($out, qr/Loading DB routines from perl5db.pl version/, 'loading line');
    like($out, qr{main::\(t/eg/04-fib.pl:4\):\s*\$\| = 1;}, 'line 4');
}

{
    my @out = $debugger->step_in;
    cmp_deeply(\@out, ['main::', 't/eg/04-fib.pl', 22, 'my $res = fib(10);'], 'line 22')
        or diag($debugger->buffer);
}

{
    my $out = $debugger->list_break_watch_action;
    like($out, qr/^\s*DB<\d+> $/, 'no breakpoint in scalar context');
}

SKIP: {
    skip('Fix list_break_watch_action in LIST context', 1);
    my @out = $debugger->list_break_watch_action;
    cmp_deeply(\@out, re('^DB<\d+> $'), 'no breakpoint in list context')
        or diag($debugger->buffer);
}

{
    ok($debugger->set_breakpoint('t/eg/04-fib.pl', 'fibx'), 'set_breakpoint');

    my $out = $debugger->list_break_watch_action;
    ok($out =~ s/DB<\d+> $/DB<> /, 'replace number as it can be different on other versions of perl');
    is($out, 't/eg/04-fib.pl:
 17:	    my $n = shift;
   break if (1)
  DB<> ', 'list_break_wath_action');
}

SKIP: {
    skip('Fix list_break_watch_action in LIST context', 1);
    my @out = $debugger->list_break_watch_action;
    cmp_deeply(\@out, [undef, undef, undef, undef], 'breakpoints in list context') or
        diag($debugger->buffer);
}

{
    my @out = $debugger->run;
    cmp_deeply(\@out, ['main::fibx', 't/eg/04-fib.pl', 17, '    my $n = shift;'], 'line 17')
        or diag($debugger->buffer);
}

{
    my @out = $debugger->get_stack_trace;
    my $trace = q($ = main::fibx(9) called from file `t/eg/04-fib.pl' line 12
$ = main::fib(10) called from file `t/eg/04-fib.pl' line 22);

    cmp_deeply(\@out, [$trace], 'stack trace')
        or diag($debugger->buffer);

    my $out = $debugger->get_stack_trace;
    is($out, q($ = main::fibx(9) called from file `t/eg/04-fib.pl' line 12
$ = main::fib(10) called from file `t/eg/04-fib.pl' line 22), 'stack trace in scalar context');
}

{
    my @out = $debugger->run(10);
    cmp_deeply(\@out, ['main::fib', 't/eg/04-fib.pl', 10, '    return 0 if $n == 0;'], 'line 10')
        or diag($debugger->buffer);
}

{
    my @out = $debugger->get_stack_trace;
    my $trace = q($ = main::fib(9) called from file `t/eg/04-fib.pl' line 18
$ = main::fibx(9) called from file `t/eg/04-fib.pl' line 12
$ = main::fib(10) called from file `t/eg/04-fib.pl' line 22);

    cmp_deeply(\@out, [$trace], 'stack trace')
        or diag($debugger->buffer);
    my $out = $debugger->get_stack_trace;
    is($out, q($ = main::fib(9) called from file `t/eg/04-fib.pl' line 18
$ = main::fibx(9) called from file `t/eg/04-fib.pl' line 12
$ = main::fib(10) called from file `t/eg/04-fib.pl' line 22), 'stack trace in scalar context');
}

# apparently  c 10 adds a breakpoint
{
    my $out = $debugger->list_break_watch_action;
    ok($out =~ s/DB<\d+> $/DB<> /, 'replace number as it can be different on other versions of perl');
    is($out, 't/eg/04-fib.pl:
 10:	    return 0 if $n == 0;
 17:	    my $n = shift;
   break if (1)
  DB<> ', 'list_break_wath_action');
}

{
    ok($debugger->remove_breakpoint('t/eg/04-fib.pl', 17), 'remove_breakpoint');
    my $out = $debugger->list_break_watch_action;
    ok($out =~ s/DB<\d+> $/DB<> /, 'replace number as it can be different on other versions of perl');
    is($out, 't/eg/04-fib.pl:
 10:	    return 0 if $n == 0;
  DB<> ', 'list_break_wath_action');
}

{
    ok($debugger->set_breakpoint('t/eg/04-fib.pl', 23), 'set_breakpoint in scalar context');
}

{
    ok(! $debugger->set_breakpoint('t/eg/04-fib.pl', 5), 'set_breakpoint fails');
}

{
    my $out = $debugger->list_break_watch_action;
    ok($out =~ s/DB<\d+> $/DB<> /, 'replace number as it can be different on other versions of perl');
    is($out, 't/eg/04-fib.pl:
 10:	    return 0 if $n == 0;
 23:	print "$res\n";
   break if (1)
  DB<> ', 'list_break_wath_action');
}

{
    ok($debugger->remove_breakpoint('t/eg/04-fib.pl', 10), 'remove_breakpoint');
    my $out = $debugger->run;
    ok($out =~ s/DB<\d+> $/DB<> /, 'replace number as it can be different on other versions of perl');
    is($out, 'main::(t/eg/04-fib.pl:23):	print "$res\n";
  DB<> ', 'run till breakpoint');
}

{
    $debugger->step_in;
    my @out = $debugger->step_in;
    cmp_deeply(\@out, ['main::fiball', 't/eg/04-fib.pl', 27, '    my ($n) = @_;'], 'line 27')
        or diag($debugger->buffer);
}
  
{
    my @out = $debugger->get_stack_trace;
    my $trace = q(. = main::fiball(3) called from file `t/eg/04-fib.pl' line 37);
    cmp_deeply(\@out, [$trace], 'stack trace')
        or diag($debugger->buffer);
}

{
    my @out = $debugger->step_out;
    cmp_deeply(\@out, ['main::', 't/eg/04-fib.pl', 38, 'my $f4 = fiball(4);', undef]);
    # It think the last undef is the return value in void context
}

{
    my @out = $debugger->step_in;
    cmp_deeply(\@out, ['main::fiball', 't/eg/04-fib.pl', 27, '    my ($n) = @_;'], 'line 27')
        or diag($debugger->buffer);
}
{
    my @out = $debugger->step_in;
    cmp_deeply(\@out, ['main::fiball', 't/eg/04-fib.pl', 28, '    return 1     if $n == 1;'], 'line 28')
        or diag($debugger->buffer);
}
{
    my @out = $debugger->get_stack_trace;
    my $trace = q($ = main::fiball(4) called from file `t/eg/04-fib.pl' line 38);
    cmp_deeply(\@out, [$trace], 'stack trace')
        or diag($debugger->buffer);
}

{
    my @out = $debugger->step_out;
    cmp_deeply(\@out, ['main::', 't/eg/04-fib.pl', 39, 'my @f5 = fiball(5);', 4]);
    # array returned in scalar context so we get 4 as the last parameter, the number of elements
}


{
    my @out = $debugger->step_in;
    cmp_deeply(\@out, ['main::fiball', 't/eg/04-fib.pl', 27, '    my ($n) = @_;'], 'line 27')
        or diag($debugger->buffer);
}
{
    my @out = $debugger->step_in;
    cmp_deeply(\@out, ['main::fiball', 't/eg/04-fib.pl', 28, '    return 1     if $n == 1;'], 'line 28')
        or diag($debugger->buffer);
}
{
    my @out = $debugger->get_stack_trace;
    my $trace = q(@ = main::fiball(5) called from file `t/eg/04-fib.pl' line 39);
    cmp_deeply(\@out, [$trace], 'stack trace')
        or diag($debugger->buffer);
}

TODO: {
    local $TODO = 'handle complex return value from subroutines';

    my @out = $debugger->step_out;
    cmp_deeply(\@out, ['main::', 't/eg/04-fib.pl', 41, 'print "$f4; @f5\n";', [1, 1, 2, 3, 5]]);
}

{
    $debugger->quit;
}
