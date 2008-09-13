use strict;
use warnings;

use t::lib::Debugger;

my $pid = start_script('t/eg/02-sub.pl');

require Test::More;
import Test::More;

plan(tests => 9);

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
    like($out, qr{main::\(t/eg/02-sub.pl:4\):\s*\$\| = 1;}, 'line 4'); # TODO why does
}

{
    my @out = $debugger->step_in;
    is_deeply(\@out, ['main::', 't/eg/02-sub.pl', 6, 'my $x = 11;', 1], 'line 6');
}
{
    my @out = $debugger->step_in;
    is_deeply(\@out, ['main::', 't/eg/02-sub.pl', 7, 'my $y = 22;', 1], 'line 7');
}

{
    my @out = $debugger->step_in;
    is_deeply(\@out, ['main::', 't/eg/02-sub.pl', 8, 'my $q = f($x, $y);', 1], 'line 8')
        or diag($Padre::Debugger::response);
}

{
    my @out = $debugger->step_over;
    is_deeply(\@out, ['main::', 't/eg/02-sub.pl', 9, 'my $z = $x + $y;', 1], 'line 9')
        or diag($Padre::Debugger::response);
}
{
    my @out = $debugger->get_value('$q');
    is_deeply(\@out, [242, 2], '$q is 11*22=242')
        or diag($Padre::Debugger::response);
}
{
    my @out = $debugger->get_value('$z');
    is_deeply(\@out, ['', 3], '$z is empty');
}

{
# Debugged program terminated.  Use q to quit or R to restart,
#   use o inhibit_exit to avoid stopping after program termination,
#   h q, h R or h o to get additional info.  
#   DB<1> 
    my $out = $debugger->step_in;
    like($out, qr/Debugged program terminated/);
}
