package Padre::Plugin::Swarm::Service;
use strict;
use warnings;
use base 'Padre::Task';
use Padre::Logger;
use Padre::Swarm::Message;
use Data::Dumper;

sub new {
	shift->SUPER::new(
		prepare => 0,
		run     => 0,
		finish  => 0,
		@_,
	);
}

sub notify {
    my ($self,$handler,$message) = @_;
    TRACE( "Notify slave task '$handler' , $message" ) if DEBUG;
    $self->handle->message( $handler => $message );
    
}

############## TASK METHODS #######################

sub run {
    my $self = shift;
    
    require Scalar::Util;
    $ENV{PERL_ANYEVENT_MODEL}='Perl';
    $ENV{PERL_ANYEVENT_VERBOSE} = 8;
    require AnyEvent;
    require Padre::Plugin::Swarm::Transport::Global;
    require Padre::Plugin::Swarm::Transport::Local;
    my $rself = $self;
    Scalar::Util::weaken( $self );

    my $bailout = AnyEvent->condvar;
    $self->{bailout} = $bailout;
    $self->_setup_connections;
    
    # my $sig_catch = AnyEvent->signal( signal=>'INT',
        # cb => sub { $self->read_task_queue }
    # );
    # TRACE( "Signal catcher $sig_catch" ) if DEBUG;
    
    my $queue_poller = AnyEvent->timer( 
        after => 1,
        interval => 1 ,
        cb => sub { $self->read_task_queue },
    );
    TRACE( "Timer - $queue_poller" ) if DEBUG;

    $self->{run}++;
    $bailout->recv;
    
    $self->_teardown_connections;

    return 1;
}

sub _setup_connections {
    my $self = shift;
    
    my $global = new Padre::Plugin::Swarm::Transport::Global
                    host => 'swarm.perlide.org',
                    port => 12000;
                    
    
    TRACE( 'Global transport ' .$global ) if DEBUG;
    $global->reg_cb(
        'recv' => sub { $self->_recv('global', @_ ) }
    );
    
    $global->reg_cb(
        'connect' => sub { $self->_connect('global', @_ ) },
    );
    
    $global->reg_cb(
        'disconnect' => sub { $self->_disconnect('global', @_  ) },
    );
    
    $self->{global}  = $global;
    $global->enable;
    
    
    my $local = new Padre::Plugin::Swarm::Transport::Local;
    
    TRACE( 'Local transport ' .$local ) if DEBUG;
    $local->reg_cb(
        'recv' => sub { $self->_recv('local' ,@_ ) }
    );
    
    $local->reg_cb(
        'connect' => sub { $self->_connect('local', @_ ) },
    );
    
    $local->reg_cb(
        'disconnect' => sub { $self->_disconnect('local', @_ ) },
    );
    
    $self->{local}  = $local;
    $local->enable;
    
    
    
    
}

sub _teardown_connections {
    my $self = shift;
    my $global = delete $self->{global};
    my $local = delete $self->{local};
    $global->event('disconnect');
    $local->event('disconnect');
    
    return ();
    
}

sub finish {
	$_[0]->{finish}++;
	TRACE( "Finished called" ) if DEBUG;
	$_[0]->{bailout}->();
	return 1;
}

sub prepare {
	$_[0]->{prepare}++;
	return 1;
}

sub send_global {
    my $self = shift;
    my $message = shift;
    TRACE( "Sending GLOBAL message " , Dumper $message );
    $self->{global}->send($message);
    # implement our own loopback ?
    $self->{global}->event('recv', $message );
}


sub send_local {
    my $self = shift;
    my $message = shift;
    TRACE( "Sending LOCAL message " , Dumper $message );
    $self->{local}->send($message);
    
}

sub read_task_queue {
    my $self = shift;
    my $cancelled = $self->cancel;
    TRACE( "state of self->cancel == $cancelled" );
    TRACE( "state of self->{handle} == " . $self->{handle} ) ;
    while( my $message = $self->dequeue_nb ) {
        TRACE( 'Unhandled Incoming message' . Dumper $message );
        if ( $message->[0] eq 'message' ) {
            shift @$message;
            my ($method,@args) = @$message;
            
            eval { $self->$method(@args);};
            if ($@) {
                TRACE( $@ ) ;
            }
        }
    
    };
    if ( $cancelled ) {
        TRACE( 'Cancelled! - bailing out of event loop' ) if DEBUG;
        $self->{bailout}->send;
    }
    
    return;
}

sub _recv {
    my($self,$origin,$transport,$message) = @_;
    TRACE( "$origin  transport=$transport, " . Dumper ($message) ) ;
    die "Origin '$origin' incorrect" unless ($origin=~/global|local/);
    
    $message->{origin} = $origin;
    
    $self->handle->message( OWNER =>  $message );
    
}

sub _connect {
    my $self = shift;
    my $origin = shift;
    my $message = shift;
    $self->handle->message( STATUS => "Swarm $origin transport connected " );
    my $m = new Padre::Swarm::Message
                origin => $origin,
                type   => 'connect';
    $self->handle->message( OWNER => $m );
}


sub _disconnect {
    my $self = shift;
    my $origin = shift;
    my $message = shift;
    $self->handle->message( STATUS => "Swarm $origin transport DISCONNECTED ");
    my $m = new Padre::Swarm::Message
                origin => $origin,
                type   => 'disconnect';
    $self->handle->message( OWNER => $m );
}

1;
