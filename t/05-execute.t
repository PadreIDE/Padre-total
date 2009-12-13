use strict;
use warnings;

use t::lib::Debugger;

my ($dir, $pid) = start_script('t/eg/02-sub.pl');

require Test::More;
import Test::More;
require Test::Deep;
import Test::Deep;
my $D = re('\d+');

plan(tests => 10);

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
    cmp_deeply(\@out, ['main::', 't/eg/02-sub.pl', 6, 'my $x = 11;', $D], 'line 6')
        or diag($debugger->buffer);
}
{
    my @out = $debugger->step_in;
    cmp_deeply(\@out, ['main::', 't/eg/02-sub.pl', 7, 'my $y = 22;', $D], 'line 7')
        or diag($debugger->buffer);
}

{
    my @out = $debugger->execute_code('$abc = 23');
    cmp_deeply(\@out, ['', $D], 'execute 1')
        or diag($debugger->buffer);
}
{
    my @out = $debugger->get_value('$abc');
    cmp_deeply(\@out, [23, $D], 'execute 1')
        or diag($debugger->buffer);
}
{
    my @out = $debugger->execute_code('@qwe = (23, 42)');
    cmp_deeply(\@out, ['', $D], 'execute 2')
        or diag($debugger->buffer);
}

# TODO check the get_value on hash and array
#{
#    my @out = $debugger->get_value('@qwe');
#    cmp_deeply(\@out, [23, 42, $D], 'execute 1')
#        or diag($debugger->buffer);
#}

{
    my @out = $debugger->set_breakpoint( 't/eg/02-sub.pl', 15 );
    cmp_deeply(\@out, ['', $D], 'set_breakpoint')
        or diag($debugger->buffer);
}

{
    my @out = $debugger->run;
    cmp_deeply(\@out, ['main::f', 't/eg/02-sub.pl', 15, '   my $add   = $q + $w;', $D], 'line 15')
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
