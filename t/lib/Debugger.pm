package t::lib::Debugger;
use strict;
use warnings;

use Exporter;
use vars qw(@ISA @EXPORT);
@ISA = ('Exporter');

@EXPORT = qw(start_script start_debugger);

my $host = 'localhost';
my $port = 12345;

sub start_script {
    my ($file) = @_;
    my $pid = fork();
    die if not defined $pid;

    if (not $pid) {
        local $ENV{PERLDB_OPTS} = "RemotePort=$host:$port";
        unlink 'out', 'err';
        sleep 1;
        exec "$^X -d $file > out 2> err";
        exit 0;
    }

    return $pid;
}

sub start_debugger {
    require Padre::Debugger;
    my $debugger = Padre::Debugger->new(host => $host, port => $port);
    return $debugger;
}


1;

