package Debug::Client;

use 5.008006;
use strict;
use warnings;

our $VERSION = '0.19';

use utf8;
use IO::Socket;
use Carp qw(carp croak cluck);

use constant {
	BLANK => qq{ },
};


#######
# new
#######
sub new {
	my $class = shift;   # What class are we constructing?
	my $self  = {};      # Allocate new memory
	bless $self, $class; # Mark it of the right type
	$self->_init(@_);    # Call _init with remaining args
	return $self;
}
#######
# _init
#######
sub _init {
	my ( $self, %args ) = @_;

	$self->{local_host} = $args{host} ? $args{host} : 'localhost';
	$self->{local_port} = $args{port} ? $args{port} : 24642;

	#ToDo for IO::Socket::IP
	# $self->{porto}      = $args{porto}  ? $args{porto}  : 'tcp';
	# $self->{listen}     = $args{listen} ? $args{listen} : SOMAXCONN;
	# $self->{reuse_addr} = $args{reuse}	? $args{reuse}  : 1;

	return;
}

#######
# Method listener
#######
sub listener {
	my $self = shift;

	# Open the socket the debugger will connect to.
	my $sock = IO::Socket::INET->new(
		LocalHost => $self->{local_host},
		LocalPort => $self->{local_port},
		Proto     => 'tcp',
		Listen    => SOMAXCONN,
		ReuseAddr => 1,

		# Proto     => $self->{porto},
		# Listen    => $self->{listen},
		# ReuseAddr => $self->{reuse_addr},
	);
	$sock or carp "Could not connect to '$self->{local_host}' '$self->{local_port}' no socket :$!";
	_logger("listening on '$self->{local_host}:$self->{local_port}'");

	$self->{sock}     = $sock;
	$self->{new_sock} = $self->{sock}->accept();

	return;
}


#######
# Method buffer
#######
sub buffer {
	my $self = shift;

	return $self->{buffer};
}

#######
# Method quit
#######
sub quit {
	my $self = shift;

	return $self->_send('q');
}

#######
# Method show_line
#######
sub show_line {
	my $self = shift;

	$self->_send('.');
	$self->_get;
	$self->_prompt;

	return $self->{buffer};
}

#######
# Method get_lineinfo
#######
sub get_lineinfo {
	my $self = shift;

	$self->_send('.');
	$self->_get;
	$self->{buffer} =~ m{^[\w:]*				# module
						(?:CODE\(.*\))* 		# catch CODE(0x9b434a8)
						\( ([^\)]*):(\d+) \)	# (file):(row)
                                    }mx;
	$self->{filename} = $1;
	$self->{row}      = $2;

	return;
}

#######
# Method show_line
#######
sub show_view {
	my $self = shift;

	$self->_send('v');
	$self->_get;
	$self->_prompt;

	return $self->{buffer};
}

#######
# Method step_in
#######
sub step_in {
	my $self = shift;

	return $self->_send_get('s');
}

#######
# Method step_over
#######
sub step_over {
	my $self = shift;

	return $self->_send_get('n');
}

#######
# Method step_out
#######
sub step_out {
	my $self = shift;

	return ('Warning: Must call step_out in list context') if not wantarray;

	return $self->_send_get('r');
}

#######
# Accessor Method get_stack_trace
#######
sub get_stack_trace {
	my ($self) = @_;

	$self->_send('T');
	$self->_get;
	$self->_prompt;

	return $self->{buffer};
}

#######
# sub toggle_trace
#######
sub toggle_trace {
	my ($self) = @_;

	$self->_send('t');
	$self->_get;
	$self->_prompt;

	return $self->{buffer};
}

#######
# sub list_subroutine_names
#######
sub list_subroutine_names {
	my ( $self, $pattern ) = @_;

	if ( defined $pattern ) {
		$self->_send("S $pattern");
	} else {
		$self->_send('S');
	}

	$self->_get;
	$self->_prompt;

	return $self->{buffer};
}

#######
# sub run
#######
sub run {
	my ( $self, $param ) = @_;

	if ( defined $param ) {
		return $self->_send_get("c $param");
	} else {
		return $self->_send_get('c');
	}
}

#######
# sub set_breakpoint
#######
sub set_breakpoint {
	my ( $self, $file, $line, $cond ) = @_;

	$self->_send("f $file");
	$self->_get;

	$self->_send("b $line");
	$self->_get;

	$self->_prompt;

	# if it was successful no reply

	if ( $self->{buffer} =~ /^Subroutine [\w:]+ not found\./ ) {

		# failed
		return 0;
	} elsif ( $self->{buffer} =~ /^Line \d+ not breakable\./ ) {

		# failed to set on line number
		return 0;
	} elsif ( $self->{buffer} =~ /^\d+ levels deep in subroutine calls!/ ) {

		# failed
		return 0;
	} elsif ( $self->{buffer} =~ /\S/ ) {
		return 0;
	}
	return 1;
}

#######
# method remove_breakpoint
#######
# apparently no clear success/error report for this
sub remove_breakpoint {
	my ( $self, $file, $line ) = @_;

	$self->_send("f $file");
	$self->_get;

	$self->_send("B $line");
	$self->_get;

	return 1;
}

#######
# show_breakpoints
#######
sub show_breakpoints {
	my $self = shift;

	return $self->_send_get('L');
}

# TODO if the given $x is a reference then something (either this module or its user) should actually call x $var
#######
# Accessor get_value
#######
sub get_value {
	my ( $self, $var ) = @_;

	if ( not defined $var ) {
		$self->_send('p');
		$self->_get;
		$self->_prompt;
		return $self->{buffer};
	} elsif ( $var =~ /\@/ or $var =~ /\%/ ) {
		$self->_send("x \\$var");
		$self->_get;
		$self->_prompt;
		return $self->{buffer};
	} else {
		$self->_send("p $var");
		$self->_get;
		$self->_prompt;
		if ( $self->{buffer} =~ m/^(?:HASH|ARRAY)/ ) {
			$self->_send("x \\$var");
			$self->_get;
			$self->_prompt;
			return $self->{buffer};
		} else {
			return $self->{buffer};
		}
	}
}

#######
# sub get_p_exp
#######
sub get_p_exp {
	my ( $self, $exp ) = @_;

	$self->_send("p $exp");
	$self->_get;
	$self->_prompt;

	return $self->{buffer};
}

#######
# sub get_y_zero
#######
sub get_y_zero {
	my $self = shift;

	$self->_send("y 0");
	$self->_get;
	$self->_prompt;

	return $self->{buffer};
}

#######
# sub get_v_vars
#######
sub get_v_vars {
	my ( $self, $pattern ) = @_;

	if ( defined $pattern ) {
		$self->_send("V $pattern");
	} else {
		$self->_send('V');
	}
	$self->_get;
	$self->_prompt;

	return $self->{buffer};
}

#######
# sub get_x_vars
#######
sub get_x_vars {
	my ( $self, $pattern ) = @_;

	if ( defined $pattern ) {
		$self->_send("X $pattern");
	} else {
		$self->_send('X');
	}

	$self->_get;
	$self->_prompt;

	return $self->{buffer};
}

#######
# sub get_h_var
#######
sub get_h_var {
	my ( $self, $var ) = @_;

	if ( defined $var ) {
		$self->_send("h $var");
	} else {
		$self->_send('h');
	}

	$self->_get;

	#Tidy for Output Panel
	$self->{buffer} =~ s/(\e\[4m|\e\[24m|\e\[1m|\e\[0m)//mg;
	$self->_prompt;

	return $self->{buffer};
}

#######
# Accessor Method set_option
#######
sub set_option {
	my ( $self, $option ) = @_;

	unless ( defined $option ) {
		return 'missing option';
	}

	$self->_send("o $option");
	$self->_get;
	$self->_prompt;

	return $self->{buffer};
}
#######
# Accessor Method get_options
#######
sub get_options {
	my $self = shift;

	$self->_send('o');
	$self->_get;
	$self->_prompt;

	return $self->{buffer};
}

#######
# Method get
#######
sub get {
	my $self = shift;

	$self->_get;

	if (wantarray) {
		$self->_prompt;
		my ( $module, $file, $row, $content ) = $self->_process_line;
		return ( $module, $file, $row, $content );
	} else {
		return $self->{buffer};
	}
}

#######
# Method filename
#######
sub filename {
	my $self = shift;

	return $self->{filename};
}

#######
# Method row
#######
sub row {
	my $self = shift;

	return $self->{row};
}

#######
# Method module
#######
sub module {
	my $self = shift;

	return $self->{module};
}

#########################################
#### Internal Methods
#######
# Internal Method _get
#######
# TODO shall we add a time-out and/or a number to count down the number sysread calls that return 0 before deciding it is really done
sub _get {
	my $self = shift;

	#my $remote_host = gethostbyaddr($sock->sockaddr(), AF_INET) || 'remote';
	my $buffer = q{};
	my $ret;
	while ( $buffer !~ /DB<\d+>/ ) {
		$ret = $self->{new_sock}->sysread( $buffer, 1024, length $buffer );
		if ( not defined $ret ) {
			carp $!; # TODO better error handling?
		}

		# _logger("---- ret '$ret'\n$buffer\n---");
		if ( not $ret ) {
			last;
		}
	}
	_logger("---- ret $ret\n$buffer\n---");
	_logger("_get done");

	$self->{buffer} = $buffer;

	return $self->{buffer};
}

#######
# Internal Method _logger
#######
sub _logger {
	print "LOG: $_[0]\n" if $ENV{DEBUG_LOGGER};
	return;
}

#######
# Internal Method _process_line
#######
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
	my $self = shift;

	my $line    = BLANK;
	my $module  = BLANK;
	my $file    = BLANK;
	my $row     = BLANK;
	my $content = BLANK;

	# if ( not defined $buffer or not ref $buffer or ref $buffer ne 'SCALAR' ) {
	# carp('_process_line should be called with a reference to a scalar');
	# }

	if ( $self->{buffer} =~ /Debugged program terminated/ ) {
		$module = '<TERMINATED>';
		$self->{module} = $module;
		return $module;
	}

	my @parts = split /\n/, $self->{buffer};

	$line = pop @parts;

	#TODO $line is where all CPAN_Testers errors come from try to debug some test reports
	# http://www.nntp.perl.org/group/perl.cpan.testers/2009/12/msg6542852.html
	if ( not defined $line ) {
		croak("Debug::Client: Line is undef. Buffer is  $self->{buffer}");
	}

	# _logger("Line1: $line");
	my $cont = 0;
	if ($line) {
		if ( $line =~ /^\d+:   \s*  (.*)$/x ) {
			$cont = $1;
			$line = pop @parts;

		}
	}

	if ($line =~ m{^([\w:]*) 			# module
                  \( ([^\)]*):(\d+) \) 	# (file:row)
                  :\t? 					# :
                  (.*) 					# content
                  }mx
		)
	{
		( $module, $file, $row, $content ) = ( $1, $2, $3, $4 );
	}
	if ( $module eq BLANK || $file eq BLANK || $row eq BLANK ) {

		# unless ( defined $module || defined $file || defined $row ) {
		my $current_file = $self->show_line();

		$current_file =~ m/([\w:]*) \( (.*) : (\d+) .* /mgx;

		$module = $1;
		$file   = $2;
		$row    = $3;

	}

	if ($cont) {
		$content = $cont;
	}

	$self->{module}   = $module;
	$self->{filename} = $file;
	$self->{row}      = $row;

	return ( $module, $file, $row, $content );
}


#######
# Internal Method _prompt
#######
# It takes one argument which is a reference to a scalar that contains the
# the text sent by the debugger.
# Extracts a prompt that looks like this:   DB<3> $
# puts the number from the prompt in $self->{prompt} and also returns it.
# See 00-internal.t for test cases
sub _prompt {
	my $self = shift;

	# my $buffer = $self->{buffer};

	# if ( not defined $buffer or not ref $buffer or ref $buffer ne 'SCALAR' ) {
	# croak('_prompt should be called with a reference to a scalar');
	# }

	my $prompt;
	if ( $self->{buffer} =~ s/\s*DB<(\d+)>\s*$// ) {
		$prompt = $1;
		_logger("prompt: $prompt");
	}
	chomp $self->{buffer};

	return $self->{prompt} = $prompt;
}

#######
# Internal Method _send
#######
sub _send {
	my ( $self, $input ) = @_;

	print { $self->{new_sock} } "$input\n";

	return 1;
}

#######
# Internal Method _send_get
#######
sub _send_get {
	my ( $self, $input ) = @_;

	$self->_send($input);

	return $self->get;
}

#######
# Internal Method __send_padre
# hidden undocumented, used for dev
######
sub __send {
	my ( $self, $input ) = @_;

	$self->_send($input);
	$self->_get;
	$self->_prompt;

	return $self->{buffer};
}

#######
# Internal Method __send_np
# hidden undocumented, used for dev
######
sub __send_np {
	my ( $self, $input ) = @_;

	$self->_send($input);
	$self->_get;

	return $self->{buffer};
}

1;

__END__

=pod

=head1 NAME

Debug::Client - debugger client side code for Padre, The Perl IDE.

=head1 VERSION

This document describes Debug::Client version 0.19

=head1 SYNOPSIS

  use Debug::Client;
  my $debugger = Debug::Client->new(host => $host, port => $port);
  $debugger->listener;

Where $host is the host-name to be used by the script under test (SUT)
to access the machine where Debug::Client runs. If they are on the same machine
this should be C<localhost>.
$port can be any port number where the Debug::Client could listen.

This is the point where the external SUT needs to be launched 
by first setting 
     
  $ENV{PERLDB_OPTS} = "RemotePort=$host:$port"

then running

  perl -d script

Once the script under test was launched we can call the following:

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
  
  
  $debugger->set_breakpoint( "file", 23 ); # set breakpoint on file, line

  $debugger->get_stack_trace

=head2 Example

  my $script = 'script_to_debug.pl';
  my @args   = ('param', 'param');
  
  my $perl = $^X; # the perl might be a different perl
  my $host = 'localhost';
  my $port = 24642;
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
  $debugger->listener;
  my $out = $debugger->get;
  $out = $debugger->step_in;
  # ...

=head1 DESCRIPTION

The prime use of this module is to provide debugger functionality for Padre 0.94+, 

This module should be Perl 5.16.0 ready.

=head1 METHODS

=over 4

=item new

The constructor can get two parameters: host and port.

  my $debugger = Debug::Client->new;

  my $debugger = Debug::Client->new(host => 'remote.host.com', port => 24642);
   
Immediately after the object creation one needs to call

  $debugger->listener;
  
TODO: Is there any reason to separate the two?



=item listener

listener/hearken To listen attentively; give heed.

See C<new>

 $debugger->listener

=item buffer

Returns the content of the buffer since the last command

  $debugger->buffer;

=item quit

 $debugger->quit();

=item show_line

. (dot)

Return the internal debugger pointer to the line last executed, and print out that line.

 $debugger->show_line();

=item get_lineinfo

Return the internal debugger pointer to the line last executed, 
and generate file-name and row for where are we now. 
trying to use perl5db line-info in naff way,

 $debugger->get_lineinfo();

Then use the following as and when.

 $debugger->filename;
 $debugger->row;
 
to get filename and row for ide due to changes in perl5db v1.35 see perl5156delta

=item show_view

v [line]

View a few lines of code around the current line.

 $debugger->show_view();

=item step_in

s [expr]

Single step. 
Executes until the beginning of another statement, descending into subroutine calls. 
If an expression is supplied that includes function calls, it too will be single-stepped.

 $debugger->step_in();

Expressions not supported. 

=item step_over

 $debugger->step_over();

=item step_out

 my ($prompt, $module, $file, $row, $content, $return_value) = $debugger->step_out();

Where $prompt is just a number, probably useless

$return_value  will be undef if the function was called in VOID context

It will hold a scalar value if called in SCALAR context

It will hold a reference to an array if called in LIST context.

TODO: check what happens when the return value is a reference to a complex data structure
or when some of the elements of the returned array are themselves references

=item get_stack_trace

Sends the stack trace command C<T> to the remote debugger
and returns it as a string if called in scalar context.
Returns the prompt number and the stack trace string
when called in array context.

=item toggle_trace

Sends the stack trace command C<t> Toggle trace mode.

 $debugger->toggle_trace();

=item list_subroutine_names

Sends the stack trace command C<S> [[!]pattern] 
List subroutine names [not] matching pattern.

=item run

  $debugger->run;
  
Will run till the next breakpoint or watch or the end of
the script. (Like pressing c in the debugger).

  $debugger->run($param)

=item set_breakpoint

 $debugger->set_breakpoint($file, $line, $condition);

I<$condition is not currently used>

=item remove_breakpoint

 $debugger->remove_breakpoint( $self, $file, $line );

=item show_breakpoints

The data as (L) prints in the command line debugger.

 $debugger->show_breakpoints();

=item get_value

 my $value = $debugger->get_value($x);

If $x is a scalar value, $value will contain that value.
If it is a reference to a ARRAY or HASH then $value should be the
value of that reference?

=item get_p_exp

p expr

Same as print {$DB::OUT} expr in the current package. 
In particular, because this is just Perl's own print function, 
this means that nested data structures and objects are not dumped, 
unlike with the x command.

The DB::OUT filehandle is opened to /dev/tty, 
regardless of where STDOUT may be redirected to.
From perldebug, but defaulted to y 0

  $debugger->get_p_exp();

=item get_y_zero

From perldebug, but defaulted to y 0

 y [level [vars]]

Display all (or some) lexical variables (mnemonic: my variables) in the current 
scope or level scopes higher. You can limit the variables that you see with vars 
which works exactly as it does for the V and X commands. Requires the PadWalker 
module version 0.08 or higher; will warn if this isn't installed. 
Output is pretty-printed in the same style as for V and the format is controlled by the same options.

  $debugger->get_y_zero();

=item get_v_vars

V [pkg [vars]]

Display all (or some) variables in package (defaulting to main ) 
using a data pretty-printer (hashes show their keys and values so you see what's what, 
control characters are made printable, etc.). 
Make sure you don't put the type specifier (like $ ) there, just the symbol names, like this:

 $debugger->get_v_vars(regex);

=item get_x_vars

X [vars] Same as V currentpackage [vars]

 $debugger->get_x_vars(regex);

=item get_h_var

Enter h or `h h' for help,
For more help, type h cmd_letter, optional var

 $debugger->get_h_var();

=item set_option

o booloption ...

Set each listed Boolean option to the value 1 .
o anyoption? ...

Print out the value of one or more options.
o option=value ...

Set the value of one or more options. If the value has internal white-space, 
it should be quoted. For example, you could set o pager="less -MQeicsNfr" to 
call less with those specific options. You may use either single or double quotes, 
but if you do, you must escape any embedded instances of same sort of quote you began with, 
as well as any escaping any escapes that immediately precede that quote but 
which are not meant to escape the quote itself. In other words, you follow 
single-quoting rules irrespective of the quote; eg: o option='this isn\'t bad' or o option="She said, \"Isn't it?\"" .

For historical reasons, the =value is optional, but defaults to 1 only where 
it is safe to do so--that is, mostly for Boolean options. 
It is always better to assign a specific value using = . The option can be abbreviated, 
but for clarity probably should not be. Several options can be set together. 
See Configurable Options for a list of these.

 $debugger->set_option();

=item get_options

o

Display all options.

 $debugger->get_options();

=item get

Actually I think this is an internal method....

In SCALAR context will return all the buffer collected since the last command.

In LIST context will return ($prompt, $module, $file, $row, $content)
Where $prompt is the what the standard debugger uses for prompt. Probably not too
interesting.
$file and $row describe the location of the next instructions.
$content is the actual line - this is probably not too interesting as it is 
in the editor. $module is just the name of the module in which the current execution is.

=item filename

 $debugger->filename();

=item row

 $debugger->row();

=item module

 $debugger->module();

=back

=head2 Internal Methods

=over 4

=item * _get

=item * _logger

=item * _process_line

=item * _prompt

=item * _send

=item * _send_get

=back

=head1 BUGS AND LIMITATIONS

Warning if you use List request you may get spurious results.

When using against perl5db.pl v1.35 list mode gives an undef response, also leading single quote now correct. 
Tests are skipped for list mode against v1.35 now.

Debug::Client 0.12 tests are failing, due to changes in perl debugger, 
when using perl5db.pl v1.34

Debug::Client 0.13_01 skips added to failing tests.

 c [line|sub]

Continue, optionally inserting a one-time-only breakpoint at the specified line or subroutine.

 c is now ignoring options [line|sub]

and just performing c on it's own

I<Warning sub listen has bean deprecated>

Has bean deprecated since 0.13_04 and all future versions starting with v0.14

Perl::Critic Error Subroutine name is a homonym for built-in function

Use $debugger->listener instead

=head1 AUTHORS

Kevin Dawson E<lt>bowtie@cpan.orgE<gt>

Gabor Szabo E<lt>gabor@szabgab.comE<gt>

=head1 CONTRIBUTORS

Breno G. de Oliveira E<lt>garu at cpan.orgE<gt>

Ahmad M. Zawawi E<lt>ahmad.zawawi@gmail.comE<gt>

Mark Gardner E<lt>mjgardner@cpan.orgE<gt>

Wolfram Humann E<lt>whumann@cpan.org<gt> 

=head1 COPYRIGHT

Copyright 2008-2012 Gabor Szabo/Kevin Dawson

=head1 LICENSE

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl 5 itself.

=head1 WARRANTY

There is no warranty whatsoever.
If you lose data or your hair because of this program,
that's your problem.

=head1 CREDITS and THANKS

Originally started out from the remote-port.pl script from 
Pro Perl Debugging written by Richard Foley.

=head1 See Also

L<GRID::Machine::remotedebugtut>

L<Devel::ebug>

L<Devel::Trepan>

=cut
