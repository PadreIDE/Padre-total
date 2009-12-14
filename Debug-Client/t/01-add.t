use strict;
use warnings;

use t::lib::Debugger;

my ($dir, $pid) = start_script('t/eg/01-add.pl');

require Test::More;
import Test::More;
require Test::Deep;
import Test::Deep;
my $PROMPT = re('\d+');

plan(tests => 7);

diag("PID $pid");
my $debugger = start_debugger();
isa_ok($debugger, 'Debug::Client');


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
    like($out, qr{main::\(t/eg/01-add.pl:4\):\s*\$\| = 1;}, 'line 4');
}


{
    my @out = $debugger->step_in;
    cmp_deeply(\@out, [$PROMPT, 'main::', 't/eg/01-add.pl', 6, 'my $x = 1;'], 'line 6')
        or diag($debugger->buffer);
}
{
    my @out = $debugger->step_in;
    cmp_deeply(\@out, [$PROMPT, 'main::', 't/eg/01-add.pl', 7, 'my $y = 2;'], 'line 7')
        or diag($debugger->buffer);
}

{
    my @out = $debugger->show_line;
    cmp_deeply(\@out, [$PROMPT, 'main::', 't/eg/01-add.pl', 7, 'my $y = 2;'], 'line 7')
        or diag($debugger->buffer);
}
{
    my @out = $debugger->step_in;
    cmp_deeply(\@out, [$PROMPT, 'main::', 't/eg/01-add.pl', 8, 'my $z = $x + $y;'], 'line 8')
        or diag($debugger->buffer);
}
{
    $debugger->quit;
    sleep 1;
}
