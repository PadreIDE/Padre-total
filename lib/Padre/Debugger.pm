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

  $out = $debugger->run;

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

sub step_in   { $_[0]->_send('s') }
sub run       { $_[0]->_send('r') }
sub quit      { $_[0]->_send('q') }
sub show_line { $_[0]->_send('.') }

sub get {
    my ($self) = @_;
    #my $remote_host = gethostbyaddr($sock->sockaddr(), AF_INET) || 'remote';

    my $buf = '';
    $self->{new_sock}->sysread($buf, 1024, length $buf) while $buf !~ /DB<\d+>/;

    return $buf;
}

sub _send {
    my ($self, $input) = @_;

    #print "Sending '$input'\n";
    print { $self->{new_sock} } "$input\n";

    return $self->get;
}


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
