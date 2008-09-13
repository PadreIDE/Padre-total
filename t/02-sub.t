use strict;
use warnings;

use t::lib::Debugger;

my $pid = start_script('t/eg/02-sub.pl');

require Test::More;
import Test::More;

plan(tests => 6);

my $debugger = start_debugger();

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
    like($out, qr{main::\(t/eg/02-sub.pl:4\):\s*\$\| = 1;}, 'line 4'); # TODO why does
}

{
    my $out = $debugger->step_in;
    like($out, qr{main::\(t/eg/02-sub.pl:6\):\s*my \$x = 1;}, 'line 6');
}
{
    my $out = $debugger->step_in;
    like($out, qr{main::\(t/eg/02-sub.pl:7\):\s*my \$y = 2;}, 'line 7');
    #diag($out);
}

{
    my $out = $debugger->step_in;
    #like($out, qr{main::\(t/eg/02-sub.pl:7\):\s*my \$y = 2;}, 'line 7');
    like($out, qr{main::\(t/eg/02-sub.pl:8\):\s*my \$q = f\(\$x, \$y\);}, 'line 8');
    #diag($out);
}

{
    my $out = $debugger->step_in;
    #diag($out);
    $out =~ s/\n\s*DB<\d+>//;
    $out =~ s/\s+$//;
    chomp $out;
    is($out, 'main::f(t/eg/02-sub.pl:13):' . "\t" . '   my ($q, $w) = @_;', 'line 13');
}

