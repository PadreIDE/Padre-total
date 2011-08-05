#!/usr/bin/perl
package MyApp;
use threads;
use Wx;
use base 'Wx::App';

sub OnInit {
   my $self = shift;

    my $frame = Wx::Frame->new( undef,           # parent window
                                -1,              # ID -1 means any
                                'wxPerl rules',  # title
                                [-1, -1],         # default position
                                [250, 150],       # size
                               );

   $frame->Show(1);


}

1;

package main;
use threads;
my $app = MyApp->new;

my $tid = threads->create(\&background, 1 );
warn "Created $tid";

$app->MainLoop;

$tid->kill('SIGTERM')->join;

exit 0;

### Thread
sub background {
   my $freq = shift;
local $ENV{PERL_ANYEVENT_MODEL} = 'Perl';
require AnyEvent;
require IO::Socket::Multicast;

   my $bailout = AnyEvent->condvar;

   my $timer = AnyEvent->timer( interval => $freq , cb => \&timer_poll );
   my $signal= AnyEvent->signal( signal => 'TERM' , cb => $bailout );

   my $client = IO::Socket::Multicast->new(
                LocalPort => 12000,
                ReuseAddr => 1,
   ) or die $!;
   $client->mcast_add('239.255.255.1'); #should have the interface
   $client->mcast_loopback( 1 );
   my $g = AnyEvent->io( poll=>'r' , fh => $client , cb => sub { client_socket_read($client) } );

   my $r = $bailout->recv;
   warn "Bailed out with $r";
   return;
}

sub timer_poll {
    my $time = AnyEvent->now;
    warn "Time is now $time";
}

sub client_socket_read {
    my $client = shift;
    my $message;
    $client->recv( $message, 65535 );
    warn "Got message : $message";
}
