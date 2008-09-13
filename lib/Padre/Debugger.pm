package Padre::Debugger;
use strict;
use warnings;

our $VERSION = '0.01';

use IO::Socket;

=head1 NAME

Padre::Debugger - client side code for perl debugger

=head1 SYNOPIS

  use Padre::Debugger;
  my $debugger = Padre::Debugger->new(host => $host, port => $port);
  $debugger->listen;

  # this is the point where the external script need to be launched
  # first setting 
      # $ENV{PERLDB_OPTS} = "RemotePort=localhost:12345"
  # then running
      # perl -d script
 
  my $out = $debugger->get;

  $out = $debugger->step_in;

  $out = $debugger->step_over;

  $out = $debugger->step_out;

  my ($module, $file, $row, $content, $prompt) = $debugger->step_in;

=head1 DESCRIPTION

It is currently in the Padre namespace but it does not have any Padre
related code so at one point it will be renamed. For now I want it to
be out to be tested by the CPAN Testers.

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

sub step_in   { $_[0]->send_get('s') }
sub step_over { $_[0]->send_get('n') }
sub quit      { $_[0]->_send_get('q') }
sub show_line { $_[0]->send_get('.') }


sub step_out  { 
    my ($self) = @_;
    $self->_send('r');
    my $buf = $self->_get;

    # scalar context return from main::f: 242
    # main::(t/eg/02-sub.pl:9):	my $z = $x + $y;
    if (wantarray) {
        my $prompt = _prompt(\$buf);
        my @line = _process_line(\$buf);
        my $ret;
        if ($buf =~ /^scalar context return from (\S+): (.*)/s) {
            $ret = $2;
        }
        return (@line, $prompt, $ret);
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
    }
    die "Unknown parameter '$var'\n";
}

sub _get {
    my ($self) = @_;

    #my $remote_host = gethostbyaddr($sock->sockaddr(), AF_INET) || 'remote';
    my $buf = '';
    $self->{new_sock}->sysread($buf, 1024, length $buf) while $buf !~ /DB<\d+>/;

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
