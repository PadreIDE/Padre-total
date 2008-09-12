package Padre::Debugger;
use strict;
use warnings;

our $VERSION = '0.01';

use IO::Socket;
use Term::ReadLine;
use Readonly;
Readonly::Scalar my $BIGNUM => 65536;

# Based on the remoteport.pl script from Pro Perl Debugging written by Richard Foley.

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

sub step  { $_[0]->_send("s") }
sub run   { $_[0]->_send("r") }
sub quit  { $_[0]->_send("q") }

sub get {
    my ($self) = @_;
    # Try to pick up the remote hostname for the prompt.
    #my $remote_host = gethostbyaddr($sock->sockaddr(), AF_INET) || 'remote';

    # Drop out if the remote debugger went away.
    my $buf = '';
    #sysread($self->{new_sock}, $buf, $BIGNUM) or die;
    $self->{new_sock}->sysread($buf, 1024, length $buf) while $buf !~ /DB<\d+>/;

    return $buf;
}

sub _send {
    my ($self, $input) = @_;

    #print "Sending '$input'\n";
    print { $self->{new_sock} } "$input\n";

    return $self->get;
    #return;
}




1;
