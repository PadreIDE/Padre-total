use strict;
use warnings;

use Getopt::Long qw(GetOptions);
use Pod::Usage qw(pod2usage);

my %opt = (
	port => 12345,
	perl => $^X, # allow the user to supply the path to another perl
	host => 'localhost',
);

usage() if not @ARGV;
GetOptions(\%opt,
	'help',
	'port=i',
	'perl=s',
) or usage();
usage() if $opt{help};

my ($script, @args) = @ARGV;

=pod

my $pid = fork();
die if not defined $pid;
  
if (not $pid) {
	local $ENV{PERLDB_OPTS} = "RemotePort=$opt{host}:$opt{port}";
	exec("$opt{perl} -d $script @args");
}
print "PID: $pid\n";

=cut
use Cwd qw(cwd);

my $process;
if ($^O =~ /win32/i) {
	require Win32::Process;
	require Win32;
	local $ENV{PERLDB_OPTS} = "RemotePort=$opt{host}:$opt{port}";
	Win32::Process::Create($process, $opt{perl}, "-d $script @args", 0, 0, cwd);
}
print "launched " . $process->GetProcessID .  "\n";

require Debug::Client;
my $debugger = Debug::Client->new(
	host => $opt{host},
	port => $opt{port},
);
$debugger->listen;
my $out = $debugger->get;
print $out;

#$out = $debugger->step_in;
  # ...

# On Windows kill() does not seem to have effect
# print "Killing the script...\n";
# kill 9, $pid;
# Win32::Process
#$process->Kill(0);

sub usage {
	pod2usage();
}


=head1 SYNOPSIS

  script param param

  --port PORT                  defaults to 12345
  --help                       This help
  --perl /path/to/other/perl   defaults to current perl

=cut

