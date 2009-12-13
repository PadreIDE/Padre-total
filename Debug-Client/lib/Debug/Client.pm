package Debug::Client;
use strict;
use warnings;
use 5.006;

our $VERSION = '0.04';

use IO::Socket;

=head1 NAME

Debug::Client - client side code for perl debugger

=head1 SYNOPIS

  use Debug::Client;
  my $debugger = Debug::Client->new(host => $host, port => $port);
  $debugger->listen;

  # this is the point where the external script need to be launched
  # first setting 
      # $ENV{PERLDB_OPTS} = "RemotePort=$host:$port"
  # then running
      # perl -d script
 
  my $out = $debugger->get;

  $out = $debugger->step_in;

  $out = $debugger->step_over;


  my ($module, $file, $row, $content, $prompt) = $debugger->step_in;
  my ($module, $file, $row, $content, $prompt, $return_value) = $debugger->step_out;
  my ($value, $prompt) = $debugger->get_value('$x');

  $debugger->run();         # run till end of breakpoint or watch
  $debugger->run( 42 );     # run till line 42  (c in the debugger)
  $debugger->run( 'foo' );  # tun till beginning of sub

  $debugger->execute_code

  $debugger->set_breakpoint( "file", 23 ); # 	set breakpoint on file, line

  $debugger->get_stack_trace

Other planned methods:

  $debugger->set_breakpoint( "file", 23, COND ); # 	set breakpoint on file, line, on condition
  $debugger->set_breakpoint( "file", subname, [COND] )

  $debugger->set_watch
  $debugger->remove_watch
  $debugger->remove_breakpoint


  $debugger->watch_variable   (to make it easy to display values of variables)

=head1 DESCRIPTION

=cut



sub new {
    my ($class, %args) = @_;
    my $self = bless {}, $class;

    %args = (host => 'localhost', port => 12345,
             %args);

    die("Usage: $0 hostname portno") unless ($args{host} =~ /\w+/ && $args{port} =~ /^\d+$/);

    # Open the socket the debugger will connect to.
    my $sock = IO::Socket::INET->new(
                   LocalHost => $args{host},
                   LocalPort => $args{port},
                   Proto     => 'tcp',
                   Listen    => SOMAXCONN,
                   Reuse     => 1);
    $sock or die "no socket :$!";
    #print "listening on $args{host}:$args{port}\n";
    $self->{sock} = $sock;

    return $self;
}

sub listen {
    my ($self) = @_;

    $self->{new_sock} = $self->{sock}->accept();
    return;

}

=head2 buffer

return the content of the buffer since the last command

  $debugger->buffer;

=cut

sub buffer {
    my ($self) = @_;
    return $self->{buffer};
}

sub step_in   { $_[0]->send_get('s') }
sub step_over { $_[0]->send_get('n') }
sub quit      { $_[0]->_send('q')    }
sub show_line { $_[0]->send_get('.') }

sub get_stack_trace {
    my ($self) = @_;
    $self->_send('T');
    my $buf = $self->_get;

    if (wantarray) {
        my $prompt = _prompt(\$buf);
        return($buf, $prompt);
    } else {
        return $buf;
    }
}



sub run       { 
    my ($self, $param) = @_;
    if (not defined $param) {
        $self->send_get('c');
    } else {
        $self->send_get("c $param");
    }
}

sub step_out  { 
    my ($self) = @_;
    $self->_send('r');
    my $buf = $self->_get;

    # scalar context return from main::f: 242
    # main::(t/eg/02-sub.pl:9):	my $z = $x + $y;

    # list context return from main::g:
    # 0  'baz'
    # 1  'foo
    # bar'
    # 2  'moo'
    # main::(t/eg/03-return.pl:10):	$x++;

    if (wantarray) {
        my $prompt = _prompt(\$buf);
        my @line = _process_line(\$buf);
        my $ret;
        my $context;
        if ($buf =~ /^(scalar|list) context return from (\S+):\s*(.*)/s) {
            $context = $1;
            $ret = $3;
        }
        #if ($context and $context eq 'list') {
            # TODO can we parse this inteligently in the general case?
        #}
        return (@line, $prompt, $ret);
    } else {
        return $buf;
    }
}

#  TODO: Line 15 not breakable.
sub set_breakpoint {
    my ($self, $file, $line, $cond) = @_;

    $self->_send("f $file");
    my $b = $self->_get;
    # Already in t/eg/02-sub.pl.

    $self->_send("b $line");
    my $buf = $self->_get;
    if (wantarray) {
        my $prompt = _prompt(\$buf);
        return($buf, $prompt);
    } else {
        return $buf;
    }
}


sub execute_code {
    my ($self, $code) = @_;
    return if not defined $code;
    $self->_send($code);
    my $buf = $self->_get;
    if (wantarray) {
       my $prompt = _prompt(\$buf);
       return ($buf, $prompt);
    } else {
       return $buf;
    }
}

sub get_value {
    my ($self, $var) = @_;
    die "no parameter given\n" if not defined $var;

    if ($var =~ /^\$/) {
        $self->_send("p $var");
        my $buf = $self->_get;
        if (wantarray) {
            my $prompt = _prompt(\$buf);
            return ($buf, $prompt);
        } else {
            return $buf
        }
    } elsif ($var =~ /\@/ or $var =~ /\%/) {
        $self->_send("x \\$var");
        my $buf = $self->_get;
        if (wantarray) {
            my $prompt = _prompt(\$buf);
            my $data_ref = _parse_dumper($buf);
            return ($data_ref, $prompt);
        } else {
            return $buf
        }
    }
    die "Unknown parameter '$var'\n";
}

sub _parse_dumper {
    my ($str) = @_;    
}

# TODO shall we add a timeout and/or a number to count down the number
# sysread calls that return 0 before deciding it is really done
sub _get {
    my ($self) = @_;

    #my $remote_host = gethostbyaddr($sock->sockaddr(), AF_INET) || 'remote';
    my $buf = '';
    while ($buf !~ /DB<\d+>/) {
        my $ret = $self->{new_sock}->sysread($buf, 1024, length $buf);
        if (not defined $ret) {
            die $!; # TODO better error handling?
        }
        logger("---- ret '$ret'\n$buf\n---");
        if (not $ret) {
            last;
        }
    }
    logger("_get done");

    $self->{buffer} = $buf;
    return $buf;
}

sub _prompt {
    my ($buf) = @_;
    my $prompt;
    if ($$buf =~ s/\s*DB<(\d+)>\s*$//) {
        $prompt = $1;
    }
    chomp($$buf);
    return $prompt;
}

sub _process_line {
    my ($buf) = @_;

    my @parts = split /\n/, $$buf;
    my $line = pop @parts;
    $$buf = join "\n", @parts;

    my ($module, $file, $row, $content);
    # the last line before 
    # main::(t/eg/01-add.pl:8):  my $z = $x + $y;
    if ($line =~ /^([\w:]*)\(([^\)]*):(\d+)\):\t(.*)/m) {
        ($module, $file, $row, $content) = ($1, $2, $3, $4);
    }
    return ($module, $file, $row, $content);
}

sub get {
    my ($self) = @_;

    my $buf = $self->_get;

    if (wantarray) {
        my $prompt = _prompt(\$buf);
        my ($module, $file, $row, $content) = _process_line(\$buf);
        return ($module, $file, $row, $content, $prompt);
    } else {
        return $buf;
    }
}

sub _send {
    my ($self, $input) = @_;

    #print "Sending '$input'\n";
    print { $self->{new_sock} } "$input\n";
}

sub send_get {
    my ($self, $input) = @_;
    $self->_send($input);

    return $self->get;
}

sub logger {
    print "$_[0]\n" if $ENV{DEBUG_LOGGER};
}


=head1 See Also

L<GRID::Machine::remotedebugtut>

=head1 COPYRIGHT

Copyright 2008 Gabor Szabo. L<http://www.szabgab.com/>

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
