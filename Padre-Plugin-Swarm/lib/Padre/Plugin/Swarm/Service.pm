package Padre::Plugin::Swarm::Service;
use strict;
use warnings;
use Padre::Task   ();
our @ISA = 'Padre::Task';

use Data::Dumper;

sub notify {
    my ($self,$handler,$message);
    $self->handle->message( $handler => $message );
    
}

############## TASK METHODS #######################

sub run {
    my $self = shift;
    
    require Scalar::Util;
    local $ENV{PERL_ANYEVENT_MODEL}='Perl';
    require AnyEvent;
    
    my $rself = $self;
    Scalar::Util::weaken( $self );

    my $bailout = AnyEvent->condvar;
    $self->{bailout} = $bailout;
    
    my $sig_catch = AnyEvent->signal( signal=>'INT',
        cb => sub { $self->read_task_queue }
    );
    
    
    my $queue_poller = AnyEvent->timer( every => 0.05 ,
        cb => sub { $self->read_task_queue },
    );
    
    $self->_setup_connections;
    
    $bailout->recv;
    #$self->handle->message( OWNER => $object, @lines );
    
    
    return;
    
}

sub _setup_connections {
    my $self = shift;
    
    my $global = new Padre::Plugin::Swarm::Transport::Global
                    host => 'swarm.perlide.org',
                    port => 12000;
    
    
    $global->reg_cb(
        'recv' => sub { $self->_recv( shift ) }
    );
    
    $global->reg_cb(
        'connect' => sub { $self->_connect( shift ) },
    );
    
    $global->reg_cb(
        'disconnect' => sub { $self->_disconnect( shift ) },
    );
    
    
}

sub send_global {
    my $self = shift;
    my $message = shift;
    $self->{global}->send($message);
    
}


sub send_local {
    my $self = shift;
    my $message = shift;
    $self->{local}->send($message);
    
}

sub read_task_queue {
    my $self = shift;
    my @messages = $self->handle->dequeue_nb;
    warn @messages;
    
    
}

1;
