package t::lib::Debugger;
use strict;
use warnings;

use File::Temp qw(tempdir);


use Exporter;
use vars qw(@ISA @EXPORT);
@ISA = ('Exporter');

@EXPORT = qw(start_script start_debugger slurp);

my $host = 'localhost';
my $port = 12345 + int rand(1000);

sub start_script {
    my ($file) = @_;
    my $dir = tempdir(CLEANUP => 0);
    my $path = $dir;
    if ($^O =~ /Win32/i) {
        require Win32;
        $path = Win32::GetLongPathName($path);
    }
    
    my $pid = fork();
    die if not defined $pid;

    if (not $pid) {
        local $ENV{PERLDB_OPTS} = "RemotePort=$host:$port";
        sleep 1;
        #warn "path '$path'";
        exec qq($^X -d $file > "$path/out" 2> "$path/err");
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

sub slurp {
    my ($file) = @_;

    open my $fh, '<', $file or die "Could not open '$file' $!";
    local $/ = undef;
    return <$fh>;
}
1;

