use strict;
use warnings;

use t::lib::Debugger;

my ($dir, $pid) = start_script('t/eg/02-sub.pl');

require Test::More;
import Test::More;
require Test::Deep;
import Test::Deep;
my $D = re('\d+');

plan(tests => 13);

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
    my @out = $debugger->step_in;
    cmp_deeply(\@out, ['main::', 't/eg/02-sub.pl', 8, 'my $q = f($x, $y);', $D], 'line 8')
        or diag($debugger->buffer);
}

{
    my @out = $debugger->step_in;
    cmp_deeply(\@out, ['main::f', 't/eg/02-sub.pl', 13, '   my ($q, $w) = @_;', $D], 'line 13')
        or diag($debugger->buffer);
}

{
    my @out = $debugger->step_in;
    cmp_deeply(\@out, ['main::f', 't/eg/02-sub.pl', 14, '   my $multi = $q * $w;', $D], 'line 14')
        or diag($debugger->buffer);
}

{
    my @out = $debugger->step_in;
    cmp_deeply(\@out, ['main::f', 't/eg/02-sub.pl', 15, '   my $add   = $q + $w;', $D], 'line 15')
        or diag($debugger->buffer);
}

{
    my @out = $debugger->step_in;
    cmp_deeply(\@out, ['main::f', 't/eg/02-sub.pl', 16, '   return $multi;', $D], 'line 16')
        or diag($debugger->buffer);
}

{
    my @out = $debugger->step_in;
    cmp_deeply(\@out, ['main::', 't/eg/02-sub.pl', 9, 'my $z = $x + $y;', $D], 'line 9')
        or diag($debugger->buffer);
}

{
    my @out = $debugger->get_value('$q');
    cmp_deeply(\@out, [242, $D], '$q is 11*22=242')
        or diag($debugger->buffer);
}
{
    my @out = $debugger->get_value('$z');
    cmp_deeply(\@out, ['', $D], '$z is empty')
        or diag($debugger->buffer);
}

{
# Debugged program terminated.  Use q to quit or R to restart,
#   use o inhibit_exit to avoid stopping after program termination,
#   h q, h R or h o to get additional info.  
#   DB<1> 
    my $out = $debugger->step_in;
    like($out, qr/Debugged program terminated/);
}

{
    $debugger->quit;
}
