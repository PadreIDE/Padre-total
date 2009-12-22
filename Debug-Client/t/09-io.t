use strict;
use warnings;

use t::lib::Debugger;

my ($dir, $pid) = start_script('t/eg/05-io.pl');
my $path = $dir;
if ($^O =~ /Win32/i) {
    require Win32;
    $path = Win32::GetLongPathName($dir);
}

require Test::More;
import Test::More;
require Test::Deep;
import Test::Deep;

plan(tests => 23);

diag("Dir '$dir' Path '$path'");

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
    like($out, qr{main::\(t/eg/05-io.pl:4\):\s*\$\| = 1;}, 'line 4');
}

diag("Perl version '$]'");
my $prefix = (substr($], 0, 5) eq '5.006') ? "Default die handler restored.\n" : '';
# see relevant fail report here:
# http://www.nntp.perl.org/group/perl.cpan.testers/2009/12/msg6486949.html
# http://www.nntp.perl.org/group/perl.cpan.testers/2009/12/msg6481372.html

{
    my @out = $debugger->step_in;
    cmp_deeply(\@out, ['main::', 't/eg/05-io.pl', 6, 'print "One\n";'], 'line 6')
        or diag($debugger->buffer);
}

{
    my @out = $debugger->step_in;
    cmp_deeply(\@out, ['main::', 't/eg/05-io.pl', 7, 'print STDERR "Two\n";'], 'line 7')
        or diag($debugger->buffer);
}

{
    my $out = slurp("$path/out");
    is($out, "One\n", 'STDOUT has One');
    my $err = slurp("$path/err");
    is($err, "${prefix}", 'STDERR is empty');
}

{
    my @out = $debugger->step_in;
    cmp_deeply(\@out, ['main::', 't/eg/05-io.pl', 8, 'print "Three\n";'], 'line 8')
        or diag($debugger->buffer);
}

{
    my $out = slurp("$path/out");
    is($out, "One\n", 'STDOUT has One');
    my $err = slurp("$path/err");
    is($err, "${prefix}Two\n", 'STDERR has Two');
}

{
    my @out = $debugger->step_in;
    cmp_deeply(\@out, ['main::', 't/eg/05-io.pl', 9, 'print "Four";'], 'line 9')
        or diag($debugger->buffer);
}

{
    my $out = slurp("$path/out");
    is($out, "One\nThree\n", 'STDOUT has One Three');
    my $err = slurp("$path/err");
    is($err, "${prefix}Two\n", 'STDERR has Two');
}



{
    my @out = $debugger->step_in;
    cmp_deeply(\@out, ['main::', 't/eg/05-io.pl', 10, 'print "\n";'], 'line 10')
        or diag($debugger->buffer);
}

{
    my $out = slurp("$path/out");
    is($out, "One\nThree\nFour", 'STDOUT has One Three Four');
    my $err = slurp("$path/err");
    is($err, "${prefix}Two\n", 'STDERR has Two');
}

{
    my @out = $debugger->step_in;
    cmp_deeply(\@out, ['main::', 't/eg/05-io.pl', 11, 'print STDERR "Five";'], 'line 11')
        or diag($debugger->buffer);
}

{
    my $out = slurp("$path/out");
    is($out, "One\nThree\nFour\n", 'STDOUT has One Three Four');
    my $err = slurp("$path/err");
    is($err, "${prefix}Two\n", 'STDERR has Two');
}

{
        my $out = $debugger->run;
        like($out, qr/Debugged program terminated/);

}

{
    my $out = slurp("$path/out");
    is($out, "One\nThree\nFour\n", 'STDOUT has everything before quit');
    my $err = slurp("$path/err");
    is($err, "${prefix}Two\nFive\n", 'STDERR has everything before quit');
}

{
    $debugger->quit;
    sleep 1;
}


{
    my $out = slurp("$path/out");
    is($out, "One\nThree\nFour\n", 'STDOUT has everything');
    my $err = slurp("$path/err");
    is($err, "${prefix}Two\nFive\n", 'STDERR has everything');
}
