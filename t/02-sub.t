use strict;
use warnings;

my $host = 'localhost';
my $port = 12345;
#use IPC::Open3    qw(open3);

my $pid = fork();
die if not defined $pid;

if (not $pid) {
   local $ENV{PERLDB_OPTS} = "RemotePort=localhost:12345";
   unlink 'out', 'err';
   sleep 1;
   exec "$^X -d t/eg/02-sub.pl > out 2> err";
   exit 0;
}

require Test::More;
import Test::More;

plan(tests => 7);

require Padre::Debugger;
my $debugger = Padre::Debugger->new(host => $host, port => $port);
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

