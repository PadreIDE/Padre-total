package Padre::Wx::Execute;
use strict;
use warnings;

our $VERSION = '0.09';

use Wx                      qw(:everything);
use Wx::Event               qw(:everything);
use Wx::Perl::ProcessStream qw(:everything);

# this is currently not a real class, just separating the code

# $self is the Padre::MainWindow object
sub setup {
	my ( $class, $self ) = @_;

	EVT_WXP_PROCESS_STREAM_STDOUT( $self, \&evt_process_stdout );
	EVT_WXP_PROCESS_STREAM_STDERR( $self, \&evt_process_stderr );
	EVT_WXP_PROCESS_STREAM_EXIT(   $self, \&evt_process_exit );

	return;
}

sub on_run_this {
	my ($self) = @_;

	my $config = Padre->ide->get_config;
	if ($config->{save_on_run} eq 'same') {
		$self->on_save;
	} elsif ($config->{save_on_run} eq 'all_files') {
	} elsif ($config->{save_on_run} eq 'all_buffer') {
	}

	my $id   = $self->{notebook}->GetSelection;
	my $filename = $self->_get_filename($id);
	if (not $filename) {
		Wx::MessageBox( "No filename, cannot run", "Cannot run", wxOK|wxCENTRE, $self );
		return;
	}
	if (substr($filename, -3) ne '.pl') {
		Wx::MessageBox( "Currently we only support execution of .pl files", "Cannot run", wxOK|wxCENTRE, $self );
		return;
	}

	# Run the program
	my $perl = Padre->perl_interpreter;
	$self->_run( qq["perl" "$filename"] );

	return;
}

sub on_debug_this {
	my ($self) = @_;
	$self->on_save;

	my $id   = $self->{notebook}->GetSelection;
	my $filename = $self->_get_filename($id);


	my $host = 'localhost';
	my $port = 12345;

	$self->_setup_debugger($host, $port);

	local $ENV{PERLDB_OPTS} = "RemotePort=$host:$port";
	my $perl = Padre->perl_interpreter;
	$self->_run(qq["$perl" -d "$filename"]);

	return;
}

# based on remoteport from "Pro Perl Debugging by Richard Foley and Andy Lester"
sub _setup_debugger {
	my ($self, $host, $port) = @_;

#use IO::Socket;
#use Term::ReadLine;
#
#    my $term = new Term::ReadLine 'local prompter';
#
#    # Open the socket the debugger will connect to.
#    my $sock = IO::Socket::INET->new(
#                   LocalHost => $host,
#                   LocalPort => $port,
#                   Proto     => 'tcp',
#                   Listen    => SOMAXCONN,
#                   Reuse     => 1);
#    $sock or die "no socket :$!";
#
#    my $new_sock = $sock->accept();
#    my $remote_host = gethostbyaddr($sock->sockaddr(), AF_INET) || 'remote';
#    my $prompt = "($remote_host)> ";
}

sub _run {
	my ($self, $cmd) = @_;

	$self->{menu}->{perl_run_script}->Enable(0);
	$self->{menu}->{perl_run_command}->Enable(0);
	$self->{menu}->{perl_stop}->Enable(1);

	my $config = Padre->ide->get_config;

	$self->show_output();
	$self->{output}->Remove( 0, $self->{output}->GetLastPosition );

	$self->{proc} = Wx::Perl::ProcessStream->OpenProcess($cmd, 'MyName1', $self);
	if ( not $self->{proc} ) {
	   $self->{menu}->{perl_run_script}->Enable(1);
	   $self->{menu}->{perl_run_command}->Enable(1);
	   $self->{menu}->{perl_stop}->Enable(0);
	}
	return;
}

sub on_run {
	my ($self) = @_;

	my $config = Padre->ide->get_config;
	if (not $config->{command_line}) {
		$self->on_setup_run;
	}
	return if not $config->{command_line};
	$self->_run($config->{command_line});

	return;
}


sub on_setup_run {
	my ($self) = @_;

	my $config = Padre->ide->get_config;
	my $dialog = Wx::TextEntryDialog->new( $self, "Command line", "Run setup", $config->{command_line} );
	if ($dialog->ShowModal == wxID_CANCEL) {
		return;
	}
#    my @values = ($config->{startup}, grep {$_ ne $config->{startup}} qw(new nothing last));

#    my $choice = Wx::Choice->new( $dialog, -1, [300, 70], [-1, -1], \@values);

	$config->{command_line} = $dialog->GetValue;
	$dialog->Destroy;

	return;
}


sub evt_process_stdout {
	my ($self, $event) = @_;
	$event->Skip(1);
	$self->{output}->AppendText( $event->GetLine . "\n");
	return;
}

sub evt_process_stderr {
	my ($self, $event) = @_;
	$event->Skip(1);
	$self->{output}->AppendText( $event->GetLine . "\n");
	return;
}

sub evt_process_exit {
	my ($self, $event) = @_;

	$event->Skip(1);
	my $process = $event->GetProcess;
	#my $line = $event->GetLine;
	#my @buffers = @{ $process->GetStdOutBuffer };
	#my @errors = @{ $process->GetStdOutBuffer };
	#my $exitcode = $process->GetExitCode;
	$process->Destroy;

	$self->{menu}->{perl_run_script}->Enable(1);
	$self->{menu}->{perl_run_command}->Enable(1);
	$self->{menu}->{perl_stop}->Enable(0);

	return;
}

sub on_stop {
	my ($self) = @_;
	$self->{proc}->TerminateProcess if $self->{proc};
	return;
}

1;
