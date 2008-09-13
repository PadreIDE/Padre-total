use strict;
use warnings;

use t::lib::Debugger;

my $pid = start_script('t/eg/01-add.pl');

require Test::More;
import Test::More;

plan(tests => 7);

my $debugger = start_debugger();
isa_ok($debugger, 'Padre::Debugger');

$debugger->listen;

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
    my $out = $debugger->step_in;
    like($out, qr{main::\(t/eg/01-add.pl:6\):\s*my \$x = 1;}, 'line 6');
}
{
    my $out = $debugger->step_in;
    like($out, qr{main::\(t/eg/01-add.pl:7\):\s*my \$y = 2;}, 'line 7');
    #diag($out);
}

{
    my $out = $debugger->show_line;
    like($out, qr{main::\(t/eg/01-add.pl:7\):\s*my \$y = 2;}, 'line 7');
}
{
    my $out = $debugger->step_in;
    like($out, qr{main::\(t/eg/01-add.pl:8\):\s*my \$z = \$x \+ \$y;}, 'line 8');
}

