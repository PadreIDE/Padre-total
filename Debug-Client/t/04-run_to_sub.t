use strict;
use warnings;
no warnings 'once';

use t::lib::Debugger;

my $pid = start_script('t/eg/02-sub.pl');

require Test::More;
import Test::More;
require Test::Deep;
import Test::Deep;
my $PROMPT = re('\d+');

plan(tests => 5);

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
    like($out, qr{main::\(t/eg/02-sub.pl:4\):\s*\$\| = 1;}, 'line 4');
}


{
    my @out = $debugger->step_in;
    cmp_deeply(\@out, [$PROMPT, 'main::', 't/eg/02-sub.pl', 6, 'my $x = 11;'], 'line 6')
        or diag($debugger->buffer);
}

{
    my @out = $debugger->run('f');
    cmp_deeply(\@out, [$PROMPT, 'main::f', 't/eg/02-sub.pl', 16, '   my ($q, $w) = @_;'], 'line 16')
        or diag($debugger->buffer);
}

{
# Debugged program terminated.  Use q to quit or R to restart,
#   use o inhibit_exit to avoid stopping after program termination,
#   h q, h R or h o to get additional info.  
#   DB<1> 
    my $out = $debugger->run;
    like($out, qr/Debugged program terminated/);
}

{
    $debugger->quit;
}
