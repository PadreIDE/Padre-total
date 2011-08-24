package Padre::Plugin::Swarm::Transport::Global;
use strict;
use warnings;
use Padre::Logger;
use Data::Dumper;
use base qw( Object::Event );
use Padre::Swarm::Message;
use AnyEvent::Socket;
use AnyEvent::Handle;
use JSON;

our $VERSION = '0.2';

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
    $self->{g} = $g;
}

sub start_session {
    TRACE(  @_ ) ;
    my ($self,$fh) = @_;
    unless ($fh) {
        $self->event('disconnect','Connection failed ' . $!);
        return;   
    }
    my $h = AnyEvent::Handle->new(
        fh => $fh,
        json => $self->_marshal,
        on_eof => sub { $self->event('disconnect', shift ) },
    );
    
    TRACE( $h );
    $self->{h} = $h;
    $h->push_write( json => { trustme=>$$.rand() } );
    $h->push_read( json => sub { $self->event( 'see_auth' , @_ ) } );
    $self->reg_cb( 'see_auth' , \&see_auth );
    
}

sub see_auth {
    TRACE( @_ );
    
    my $self = shift;
    my $handle = shift;
    my $message = shift;
    $self->unreg_cb('start_session');
    
    $self->{token} = $message->{token};
    if ( $message->{session} eq 'authorized' ) {
        $self->{h}->on_read( sub {
                shift->push_read( json => sub { $self->event('recv',$_[1]) } );
            }
        );
        $self->event('connect'=>1);
    }
    else {
        $self->{h}->destroy;
        delete $self->{h};      
        $self->event('disconnect','Authorization failed');
        
    }
}


use Carp 'confess';
use Data::Dumper;
$Data::Dumper::Indent=1;

sub send {
    TRACE( @_ );
    my $self = shift;
    my $message = shift;
    if ( threads::shared::is_shared( $message ) ) {
        TRACE( "SEND A SHARED REFERENCE ?!?!?! - " . Dumper $message );
        
        confess "$message , is a shared value";    
    }
    $message->{token} = $self->{token};
    $self->{h}->push_write( json => $message );
    # implement our own loopback ?
    # something segfaults when I do this???
    #$self->event('recv', $message );
    
}

sub _marshal {
	JSON->new
	    ->allow_blessed
            ->convert_blessed
            ->utf8
            ->filter_json_object(\&synthetic_class );
}


sub synthetic_class {
	my $var = shift ;
	if ( exists $var->{__origin_class} ) {
		my $stub = $var->{__origin_class};
		my $msg_class = 'Padre::Swarm::Message::' . $stub;
		my $instance = bless $var , $msg_class;
		return $instance;
	} else {
		return bless $var , 'Padre::Swarm::Message';
	}
};


1;
