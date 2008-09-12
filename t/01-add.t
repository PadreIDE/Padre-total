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
   exec "$^X -d t/eg/01-add.pl > out 2> err";
   exit 0;
}

require Test::More;
import Test::More;

plan(tests => 7);

require Padre::Debugger;
my $debugger = Padre::Debugger->new(host => $host, port => $port);
isa_ok($debugger, 'Padre::Debugger');
#my ($in, $out, $err);
#my $pid = open3($in, $out, $err, "$^X t/eg/01-add.pl -d");

$debugger->listen;
#diag("launched");
#diag("---");

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
    like($out, qr{main::\(t/eg/01-add.pl:4\): \$| = 1;}, 'line 4');
}


{
    my $out = $debugger->step;
    like($out, qr{main::\(t/eg/01-add.pl:8\):	my \$x = 1;}, 'line 8');
}
{
    my $out = $debugger->step;
    like($out, qr{main::\(t/eg/01-add.pl:10\):	my \$y = 2;}, 'line 10');
    #diag($out);
}

{
    my $out = $debugger->_send('.');
    like($out, qr{main::\(t/eg/01-add.pl:10\):	my \$y = 2;}, 'line 10');
}
{
    my $out = $debugger->step;
    like($out, qr{main::\(t/eg/01-add.pl:12\):	my \$z = \$x \+ \$y;}, 'line 12');
}

