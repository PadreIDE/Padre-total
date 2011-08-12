package Padre::Plugin::Swarm::Transport::Global;
use strict;
use warnings;
use Padre::Logger;
use Data::Dumper;
use base qw( Object::Event );
use AnyEvent::Socket;
use AnyEvent::Handle;

our $VERSION = '0.11';

sub new {
    my $class = shift;
    my $self = $class->SUPER::new(@_);
    $self->reg_cb( 'start_session' => \&start_session );
    return $self;
}

sub enable {
    my  $self = shift;
    my $g = tcp_connect $self->{host} , $self->{port},
        sub { $self->event( 'start_session', shift) };
    warn "Got $g";
    $self->{g} = $g;
}

sub start_session {
    my ($self,$fh) = @_;
    unless ($fh) {
        $self->event('disconnect','Connection failed ' . $!);
        return;
        
    }
    warn "Start session $self, $fh";
    my $h = AnyEvent::Handle->new(
        fh => $fh,
        on_eof => sub { $self->event('disconnect', shift ) },
    );
    

    $self->{h} = $h;
    $h->push_write( json => { trustme=>$$.rand() } );
    $h->push_read( json => sub { $self->event( 'see_auth' , @_ ) } );
    $self->reg_cb( 'see_auth' , \&see_auth );
    
}

sub see_auth {
    my $self = shift;
    my $handle = shift;
    my $message = shift;
    warn "Seen auth " , Dumper $message;
    $self->unreg_cb('start_session');
    
    $self->{token} = $message->{token};
    if ( $message->{session} eq 'authorized' ) {
        $self->{h}->on_read( sub {
                shift->push_read( json => sub { $self->event('recv',@_) } );
            }
        );
        $self->reg_cb( 'recv', \&recv );
        $self->event(connect=>1);
    }
    else {
        $self->{h}->destroy;
        delete $self->{h};      
        $self->event('disconnect','Authorization failed');
        
    }
}

sub send {
    my $self = shift;
    my $message = shift;
    $message->{token} = $self->{token};
    $self->{h}->push_write( json => $message );
    
}

# sub recv {
    # my $self = shift;
    # my $handle = shift;
    # my $message = shift;
    # warn "Received " . Dumper $message;
    # 
# }

1;
