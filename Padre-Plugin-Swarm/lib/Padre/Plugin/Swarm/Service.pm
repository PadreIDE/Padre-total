package Padre::Plugin::Swarm::Service;
use strict;
use warnings;
use base 'Padre::Task';
use IO::Handle;
use Padre::Logger;
use Padre::Swarm::Message;
use Data::Dumper;
use Socket;
use Storable;
use POSIX qw(:errno_h :fcntl_h);


{
    my %sockets = ();
    my $socketid = 1;
    sub _new_socketpair {
        my $self = shift;
        my $id = $socketid++;
        
        
        my ($read,$write) = ( IO::Handle->new() , IO::Handle->new() );
        socketpair( $read, $write, AF_UNIX, SOCK_STREAM, PF_UNSPEC ) or die $!;
	binmode $read;	
        binmode $write;
        my $fd_read = $read->fileno;
        $sockets{$id} = [ $read, $write ];
        $self->{_inbound_file_descriptor} = $fd_read;
        return $self->{socketid}= $id;
    }
    
    
    sub _cleanup_socketid {
        my $self = shift;
        my $id = $self->{socketid};
        my ($read,$write) = @{ delete $sockets{$id} };
        undef $read;
        undef $write;
        return ();
    }

    
    sub _get_socketpair {
        my $self = shift;
        my $id = $self->{socketid};
        return @{ $sockets{$id} };
    }
    
}


sub new {
	shift->SUPER::new(
		prepare => 0,
		run     => 0,
		finish  => 0,
		@_,
	);
}

# sub notify {
    # my ($self,$handler,$message) = @_;
    # TRACE( "Notify slave task '$handler' , $message" ) if DEBUG;
    # $self->message( $handler => $message );
    
# # }


sub notify {
    my $self = shift;
    my $handler = shift;
    my $message = shift;
    
    eval {
        my $data = Storable::freeze( [ $handler => $message ] );
        TRACE( "Transmit storable encoded envelope size=".length($data) );
        # Cargo from AnyEvent::Handle, register_write_type =>'storable'
        my ($read,$write) = $self->_get_socketpair;
        $write->syswrite( pack "w/a*", $data );
    };
    if ($@) {
        TRACE( "Failed to send message down parent_socket , $@" );
    }
}


############## TASK METHODS #######################

sub run {
    my $self = shift;
    
    require Scalar::Util;
    
    
    # when AnyEvent detects Wx it falls back to POE (erk).
    # , tricking it into using pureperl seems to work.
    $ENV{PERL_ANYEVENT_MODEL}='Perl';
    $ENV{PERL_ANYEVENT_VERBOSE} = 8;
    require AnyEvent;
    require AnyEvent::Handle;
    require Padre::Plugin::Swarm::Transport::Global;
    require Padre::Plugin::Swarm::Transport::Local;
    TRACE( " AnyEvent loaded " );
    
    my $file_no = $self->{inbound_file_descriptor};
    
    my $inbound = IO::Handle->new();
    #    
    eval { $inbound->fdopen( $file_no , 'r'); $inbound->fdopen($file_no,'w') };
    if ($@) {
        TRACE( "Failed to open inbound channel - $@ - $! ==" . $self->{inbound_file_descriptor}  );
    }
    
    
    # TRACE( "Using inbound handle $inbound" );
    my $parent_io = AnyEvent::Handle->new(
        fh => $inbound ,
        #fh => $self->{inbound_file_descriptor},
        #on_read => sub { warn "Readable @_"; shift->push_read(storable=>\&read_parent_socket)  } ,
        on_read => sub { shift->push_read( storable => sub { $self->read_parent_socket(@_) } ) },
        on_error => sub { warn "Error on parent_io channel"; },
        on_eof   => sub { warn "EOF on parent_io channel"; }
    ) or die $! ;
    TRACE( "Using AE io handle $parent_io" );
    
    #my $io = AnyEvent->io( poll => 'r' , fh => $inbound , cb => sub { $self->read_parent_socket($inbound) } );
    
    my $bailout = AnyEvent->condvar;
    
    $self->{bailout} = $bailout;
    $self->_setup_connections;
    
    
    # the latency on this is awful , unsurprisingly
    # it would be better to have a socketpair to poll for read from our parent.
    
    # my $sig_catch = AnyEvent->signal( signal=>'INT',
        # cb => sub { $self->read_task_queue }
    # );
    # TRACE( "Signal catcher $sig_catch" ) if DEBUG;
    
    
    
    my $queue_poller = AnyEvent->timer( 
        after => 0.2,
        interval => 0.2 ,
        cb => sub { $self->read_task_queue },
    );
    TRACE( "Timer - $queue_poller" ) if DEBUG;

    $self->{run}++;
    
    ## Blocking now ... until the bailout is sent or croaked
    my $exit_mode = $bailout->recv;
    TRACE( "Bailout reached! " . $exit_mode );
    $self->_teardown_connections;
    my $cleanup = AnyEvent->condvar;
    my $graceful = AnyEvent->timer( after=>1 , cb => $cleanup );
    ## blocking for graceful cleanup
    TRACE( "Waiting for graceful exit from transports" );
    $cleanup->recv;
    
    
    TRACE( 'returning from ->run' );
    return 1;
}

sub _setup_connections {
    TRACE( @_ );
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
    TRACE( 'Teardown global' );
    eval { $self->{global}->event('disconnect'); };
    TRACE( $@ ) if $@;
    
    TRACE( 'Teardown local' );    
    eval { $self->{local}->event('disconnect'); };
    TRACE( $@ ) if $@;
    
    my $global = delete $self->{global};
    my $local = delete $self->{local};
    
    
    return ();
    
}

sub finish {
	TRACE( "Finished called" ) if DEBUG;
	
	my $self = shift;
        $self->_cleanup_socketid($self->{socketid});
        
        
        $self->{finish}++;
	
	#$_[0]->{bailout}->(); Damnit - now I am confused is this a parent or child method?????
	return 1;
}

sub prepare {
        my $self = shift;
        $self->_new_socketpair;# mutator , need to know.
        
	$_[0]->{prepare}++;
	return 1;
}

sub send_global {
    my $self = shift;
    my $message = shift;
    TRACE( "Sending GLOBAL message " , Dumper $message );# if DEBUG;
    $self->{global}->send($message);
    
}


sub send_local {
    my $self = shift;
    my $message = shift;
    TRACE( "Sending LOCAL message " , Dumper $message ) if DEBUG;
    $self->{local}->send($message);
    
}


sub shutdown_service {
    my $self = shift;
    my $reason = shift;
    $self->{bailout}->send($reason);
}

sub read_parent_socket {
    TRACE( @_ );
    my ($self,$inbound,$envelope) = @_;
    unless ( ref $envelope eq 'ARRAY' ) {
        TRACE( 'Unknown inbound envelope message: ' . Dumper $envelope );
        return;
    }
    
    my ($method,@args) = @$envelope;
    eval { $self->$method(@args) };
    if ($@) {
        TRACE( 'Method dispatch failed with ' . $@ . ' for ' . Dumper $envelope );
    }
    
}

sub read_task_queue {
    my $self = shift;
    #TRACE( 'Read task queue' );
eval {
    while( my $message = $self->child_inbox ) {
            my ($method,@args) = @$message;
            eval { $self->$method(@args);};
            if ($@) {
                TRACE( $@ ) ;
            }
        
    
    };
    if ( $self->cancelled ) {
        TRACE( 'Cancelled! - bailing out of event loop' ) ;#if DEBUG;
        $self->{bailout}->send('cancelled');
    }
 };
    
 if ($@) {
        TRACE( 'Task queue error ' . $@ )
     
 }
    return;
}

sub _recv {
    my($self,$origin,$transport,$message) = @_;
    TRACE( "$origin  transport=$transport, " . Dumper ($message) ); #  if DEBUG;
    die "Origin '$origin' incorrect" unless ($origin=~/global|local/);
    
    $message->{origin} = $origin;
    
    $self->tell_owner( $message );
    
}

sub _connect {
    my $self = shift;
    my $origin = shift;
    my $message = shift;
    TRACE( "Connected $origin" );
    $self->tell_status( "Swarm $origin transport connected" );
    my $m = new Padre::Swarm::Message
                origin => $origin,
                type   => 'connect';
    $self->tell_owner( $m );
}


sub _disconnect {
    my $self = shift;
    my $origin = shift;
    my $message = shift;
    $self->tell_status("Swarm $origin transport DISCONNECTED");
    my $m = new Padre::Swarm::Message
                origin => $origin,
                type   => 'disconnect';
    $self->tell_owner( $m );
}

1;
