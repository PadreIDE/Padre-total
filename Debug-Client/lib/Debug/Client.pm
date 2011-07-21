package Debug::Client;
use strict;
use warnings;
use 5.006;

our $VERSION = '0.12';

use IO::Socket;
use Carp ();

=head1 NAME

Debug::Client - client side code for perl debugger

=head1 SYNOPIS

  use Debug::Client;
  my $debugger = Debug::Client->new(host => $host, port => $port);
  $debugger->listen;

Where $host is the hostname to be used by the script under test (SUT)
to acces the machine where Debug::Client runs. If they are on the same machine
this should be C<localhost>.
$port can be any port number where the Debug::Client could listen.

This is the point where the external SUT needs to be launched 
by first setting 
     
  $ENV{PERLDB_OPTS} = "RemotePort=$host:$port"

then running

  perl -d script

Once the script under test wa launched we can call the following:

  my $out = $debugger->get;

  $out = $debugger->step_in;

  $out = $debugger->step_over;


  my ($prompt, $module, $file, $row, $content) = $debugger->step_in;
  my ($module, $file, $row, $content, $return_value) = $debugger->step_out;
  my $value = $debugger->get_value('$x');

  $debugger->run();         # run till end of breakpoint or watch
  $debugger->run( 42 );     # run till line 42  (c in the debugger)
  $debugger->run( 'foo' );  # run till beginning of sub

  $debugger->execute_code( '$answer = 42' );

  $debugger->execute_code( '@name = qw(foo bar)' );

  my $value = $debugger->get_value('@name');  $value is the dumped data?

  $debugger->execute_code( '%phone_book = (foo => 123, bar => 456)' );

  my $value = $debugger->get_value('%phone_book');  $value is the dumped data?
  
  
  $debugger->set_breakpoint( "file", 23 ); # 	set breakpoint on file, line

  $debugger->get_stack_trace

Other planned methods:

  $debugger->set_breakpoint( "file", 23, COND ); # 	set breakpoint on file, line, on condition
  $debugger->set_breakpoint( "file", subname, [COND] )

  $debugger->set_watch
  $debugger->remove_watch
  $debugger->remove_breakpoint


  $debugger->watch_variable   (to make it easy to display values of variables)

=head2 example

  my $script = 'script_to_debug.pl';
  my @args   = ('param', 'param');
  
  my $perl = $^X; # the perl might be a different perl
  my $host = 'localhost';
  my $port = 12345;
  my $pid = fork();
  die if not defined $pid;
  
  if (not $pid) {
	local $ENV{PERLDB_OPTS} = "RemotePort=$host:$port"
  	exec("$perl -d $script @args");
  }
  
  
  require Debug::Client;
  my $debugger = Debug::Client->new(
    host => $host,
    port => $port,
  );
  $debugger->listen;
  my $out = $debugger->get;
  $out = $debugger->step_in;
  # ...

=head1 DESCRIPTION

=cut

=head2 new

The constructor can get two parameters: host and port.

  my $d = Debug::Client->new;

  my $d = Debug::Client->new(host => 'remote.hots.com', port => 4242);
   
Immediately after the object creation one needs to call

  $d->listen;
  
TODO: Is there any reason to separate the two?

=cut

sub new {
	my ( $class, %args ) = @_;
	my $self = bless {}, $class;

	%args = (
		host => 'localhost', port => 12345,
		%args
	);

	$self->{host} = $args{host};
	$self->{port} = $args{port};

	return $self;
}

=head2 listen

See C<new>

=cut

sub listen {
	my ($self) = @_;

	# Open the socket the debugger will connect to.
	my $sock = IO::Socket::INET->new(
		LocalHost => $self->{host},
		LocalPort => $self->{port},
		Proto     => 'tcp',
		Listen    => SOMAXCONN,
		Reuse     => 1
	);
	$sock or die "Could not connect to '$self->{host}' '$self->{port}' no socket :$!";
	_logger("listening on '$self->{host}:$self->{port}'");
	$self->{sock} = $sock;

	$self->{new_sock} = $self->{sock}->accept();

	return;
}

=head2 buffer

Returns the content of the buffer since the last command

  $debugger->buffer;

=cut

sub buffer {
	my ($self) = @_;
	return $self->{buffer};
}

=head2 quit

=cut

sub quit { $_[0]->_send('q') }

=head2 show_line

=cut

sub show_line { $_[0]->send_get('.') }


=head2 step_in

=cut

sub step_in { $_[0]->send_get('s') }

=head2 step_over

=cut

sub step_over { $_[0]->send_get('n') }

=head2 step_out

 my ($prompt, $module, $file, $row, $content, $return_value) = $debugger->step_out;

Where $prompt is just a number, probably useless

$return_value  will be undef if the function was called in VOID context

It will hold a scalar value if called in SCALAR context

It will hold a reference to an array if called in LIST context.

TODO: check what happens when the return value is a reference to a complex data structure
or when some of the elements of the returned array are themselves references

=cut

sub step_out {
	my ($self) = @_;

	Carp::croak('Must call step_out in list context') if not wantarray;

	$self->_send('r');
	my $buf = $self->_get;

	# void context return from main::f
	# scalar context return from main::f: 242
	# list  context return from main::f:
	# 0 22
	# 1 34
	# main::(t/eg/02-sub.pl:9):	my $z = $x + $y;

	# list context return from main::g:
	# 0  'baz'
	# 1  'foo
	# bar'
	# 2  'moo'
	# main::(t/eg/03-return.pl:10):	$x++;

	$self->_prompt( \$buf );
	my @line = $self->_process_line( \$buf );
	my $ret;
	my $context;
	if ( $buf =~ /^(scalar|list) context return from (\S+):\s*(.*)/s ) {
		$context = $1;
		$ret     = $3;
	}

	#if ($context and $context eq 'list') {
	# TODO can we parse this inteligently in the general case?
	#}
	return ( @line, $ret );
}


=head2 get_stack_trace

Sends the stack trace command C<T> to the remote debugger
and returns it as a string if called in scalar context.
Returns the prompt number and the stack trace string
when called in array context.

=cut

sub get_stack_trace {
	my ($self) = @_;
	$self->_send('T');
	my $buf = $self->_get;

	$self->_prompt( \$buf );
	return $buf;
}

=head2 run

  $d->run;
  
Will run till the next breakpoint or watch or the end of
the script. (Like pressing c in the debugger).

  $d->run($param)

=cut

sub run {
	my ( $self, $param ) = @_;
	if ( not defined $param ) {
		$self->send_get('c');
	} else {
		$self->send_get("c $param");
	}
}


=head2 set_breakpoint

 $d->set_breakpoint($file, $line, $condition);

=cut


sub set_breakpoint {
	my ( $self, $file, $line, $cond ) = @_;

	$self->_send("f $file");
	my $b = $self->_get;

	# Already in t/eg/02-sub.pl.

	$self->_send("b $line");

	# if it was successful no reply
	# if it failed we saw two possible replies
	my $buf    = $self->_get;
	my $prompt = $self->_prompt( \$buf );
	if ( $buf =~ /^Subroutine [\w:]+ not found\./ ) {

		# failed
		return 0;
	} elsif ( $buf =~ /^Line \d+ not breakable\./ ) {

		# faild to set on line number
		return 0;
	} elsif ( $buf =~ /\S/ ) {
		return 0;
	}

	return 1;
}

# apparently no clear success/error report for this
sub remove_breakpoint {
	my ( $self, $file, $line ) = @_;

	$self->_send("f $file");
	my $b = $self->_get;

	$self->_send("B $line");
	my $buf = $self->_get;
	return 1;
}

=head2 list_break_watch_action

In scalar context returns the list of all the breakpoints 
and watches as a text output. The data as (L) prints in the
command line debugger.

In list context it returns the promt number,
and a list of hashes. Each hash has

  file =>
  line =>
  cond => 

to provide the filename, line number and the condition of the breakpoint.
In case of no condition the last one will be the number 1.

=cut

sub list_break_watch_action {
	my ($self) = @_;

	my $ret = $self->send_get('L');
	if ( not wantarray ) {
		return $ret;
	}

	# t/eg/04-fib.pl:
	#  17:      my $n = shift;
	#    break if (1)
	my $buf    = $self->buffer;
	my $prompt = $self->_prompt( \$buf );

	my @breakpoints;
	my %bp;
	my $PATH = qr{[\w./-]+};
	my $LINE = qr{\d+};
	my $CODE = qr{.*}s;
	my $COND = qr{1};       ## TODO !!!

	while ($buf) {
		if ( $buf =~ s{^($PATH):\s*($LINE):\s*($CODE)\s+break if \(($COND)\)s*}{} ) {
			my %bp = (
				file => $1,
				line => $2,
				cond => $4,
			);
			push @breakpoints, \%bp;
		} else {
			die "No breakpoint found in '$buf'";
		}
	}

	return ( $prompt, \@breakpoints );
}


=head2 execute_code

  $d->execute_code($some_code_to_execute);

=cut

sub execute_code {
	my ( $self, $code ) = @_;

	return if not defined $code;

	$self->_send($code);
	my $buf = $self->_get;
	$self->_prompt( \$buf );
	return $buf;
}

=head2 get_value

 my $value = $d->get_value($x);

If $x is a scalar value, $value will contain that value.
If it is a reference to a SCALAR, ARRAY or HASH then $value should be the
value of that reference?

=cut

# TODO if the given $x is a reference then something (either this module
# or its user) should actually call   x $var
sub get_value {
	my ( $self, $var ) = @_;
	die "no parameter given\n" if not defined $var;

	if ( $var =~ /^\$/ ) {
		$self->_send("p $var");
		my $buf = $self->_get;
		$self->_prompt( \$buf );
		return $buf;
	} elsif ( $var =~ /\@/ or $var =~ /\%/ ) {
		$self->_send("x \\$var");
		my $buf = $self->_get;
		$self->_prompt( \$buf );
		my $data_ref = _parse_dumper($buf);
		return $data_ref;
	}
	die "Unknown parameter '$var'\n";
}

sub _parse_dumper {
	my ($str) = @_;
	return $str;
}

# TODO shall we add a timeout and/or a number to count down the number
# sysread calls that return 0 before deciding it is really done
sub _get {
	my ($self) = @_;

	#my $remote_host = gethostbyaddr($sock->sockaddr(), AF_INET) || 'remote';
	my $buf = '';
	while ( $buf !~ /DB<\d+>/ ) {
		my $ret = $self->{new_sock}->sysread( $buf, 1024, length $buf );
		if ( not defined $ret ) {
			die $!; # TODO better error handling?
		}
		_logger("---- ret '$ret'\n$buf\n---");
		if ( not $ret ) {
			last;
		}
	}
	_logger("_get done");

	$self->{buffer} = $buf;
	return $buf;
}

# This is an internal method.
# It takes one argument which is a reference to a scalar that contains the
# the text sent by the debugger.
# Extracts and prompt that looks like this:   DB<3> $
# puts the number from the prompt in $self->{prompt} and also returns it.
# See 00-internal.t for test cases
sub _prompt {
	my ( $self, $buf ) = @_;

	if ( not defined $buf or not ref $buf or ref $buf ne 'SCALAR' ) {
		Carp::croak('_prompt should be called with a reference to a scalar');
	}

	my $prompt;
	if ( $$buf =~ s/\s*DB<(\d+)>\s*$// ) {
		$prompt = $1;
	}
	chomp($$buf);

	return $self->{prompt} = $prompt;
}

# Internal method that receives a reference to a scalar
# containing the data printed by the debugger
# If the output indicates that the debugger terminated return '<TERMINATED>'
# Otherwise it returns   ( $package, $file, $row, $content );
# where
#    $package   is  main::   or   Some::Module::   (the current package)
#    $file      is the full or relative path to the current file
#    $row       is the current row number
#    $content   is the content of the current row
# see 00-internal.t for test cases
sub _process_line {
	my ( $self, $buf ) = @_;

	if ( not defined $buf or not ref $buf or ref $buf ne 'SCALAR' ) {
		Carp::croak('_process_line should be called with a reference to a scalar');
	}

	if ( $$buf =~ /Debugged program terminated/ ) {
		return '<TERMINATED>';
	}

	my @parts = split /\n/, $$buf;
	my $line = pop @parts;

	# try to debug some test reports
	# http://www.nntp.perl.org/group/perl.cpan.testers/2009/12/msg6542852.html
	if ( not defined $line ) {
		Carp::croak("Debug::Client: Line is undef. Buffer is '$$buf'");
	}
	_logger("Line: '$line'");
	my $cont;
	if ( $line =~ /^\d+:   \s*  (.*)$/x ) {
		$cont = $1;
		$line = pop @parts;
		_logger("Line2: '$line'");
	}

	$$buf = join "\n", @parts;
	my ( $module, $file, $row, $content );

	# the last line before
	# main::(t/eg/01-add.pl:8):  my $z = $x + $y;
	if ($line =~ /^([\w:]*)                  # module
                  \(   ([^\)]*):(\d+)   \)   # (file:row)
                  :\t?                        # :
                  (.*)                       # content
                  /mx
		)
	{
		( $module, $file, $row, $content ) = ( $1, $2, $3, $4 );
	}
	if ($cont) {
		$content = $cont;
	}
	$self->{filename} = $file;
	$self->{row}      = $row;
	return ( $module, $file, $row, $content );
}

=head get

Actually I think this is an internal method....

In SCALAR context will return all the buffer collected since the last command.

In LIST context will return ($prompt, $module, $file, $row, $content)
Where $prompt is the what the standard debugger uses for prompt. Probably not too
interesting.
$file and $row describe the location of the next instructions.
$content is the actual line - this is probably not too interesting as it is 
in the editor. $module is just the name of the module in which the current execution is.

=cut

sub get {
	my ($self) = @_;

	my $buf = $self->_get;

	if (wantarray) {
		$self->_prompt( \$buf );
		my ( $module, $file, $row, $content ) = $self->_process_line( \$buf );
		return ( $module, $file, $row, $content );
	} else {
		return $buf;
	}
}

sub _send {
	my ( $self, $input ) = @_;

	#print "Sending '$input'\n";
	print { $self->{new_sock} } "$input\n";
}

sub send_get {
	my ( $self, $input ) = @_;
	$self->_send($input);

	return $self->get;
}

sub filename { return $_[0]->{filename} }
sub row      { return $_[0]->{row} }

sub _logger {
	print "LOG: $_[0]\n" if $ENV{DEBUG_LOGGER};
}


=head1 See Also

L<GRID::Machine::remotedebugtut>

=head1 COPYRIGHT

Copyright 2008-2011 Gabor Szabo. L<http://szabgab.com/>

=head1 LICENSE

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl 5 itself.

=head1 WARRANTY

There is no warranty whatsoever.
If you lose data or your hair because of this program,
that's your problem.

=head1 CREDITS and THANKS

Originally started out from the remoteport.pl script from 
Pro Perl Debugging written by Richard Foley.

=cut

1;
