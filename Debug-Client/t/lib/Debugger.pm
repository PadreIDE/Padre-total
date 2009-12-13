package t::lib::Debugger;
use strict;
use warnings;

use File::Temp qw(tempdir);


use Exporter;
use vars qw(@ISA @EXPORT);
@ISA = ('Exporter');

@EXPORT = qw(start_script start_debugger);

my $host = 'localhost';
my $port = 12345 + int rand(1000);

sub start_script {
    my ($file) = @_;
    my $pid = fork();
    my $dir = tempdir(CLEANUP => 1);

    die if not defined $pid;

    if (not $pid) {
        local $ENV{PERLDB_OPTS} = "RemotePort=$host:$port";
        sleep 1;
        exec "$^X -d $file > $dir/out 2> $dir/err";
        exit 0;
    }

    return ($dir, $pid);
}

sub start_debugger {
    require Debug::Client;
    my $debugger = Debug::Client->new(host => $host, port => $port);
    $debugger->listen;
    return $debugger;
}


1;

