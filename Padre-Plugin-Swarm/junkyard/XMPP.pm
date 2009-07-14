package Padre::Swarm::Transport::XMPP;

use strict;
use warnings;
use Padre::Swarm::Transport;

use AnyEvent;
use AnyEvent::XMPP::Client;
use AnyEvent::XMPP::Ext::Disco;
use AnyEvent::XMPP::Ext::MUC;
use Class::XSAccessor
   getters => {
	   connection => 'connection',
	   condvar	=> 'condvar',
	   nickname    => 'nickname',
	   credentials => 'credentials',
   };
   
use Carp qw( carp );

our @ISA = 'Padre::Swarm::Transport';

sub start {
	my $self = shift;
	warn "Starting" ;
	my $con = AnyEvent::XMPP::Client->new(
		debug => 1,
		username => $self->credentials->{username}, 
		password => $self->credentials->{password},
		host => $self->{server},
	);
#	$con->add_account(
#		$self->credentials->{username}, 
#		$self->credentials->{password},
#		$self->{server},
#	);
#
	$self->_register_xmpp_callbacks($con);

	#$con->add_extension (my $disco = AnyEvent::XMPP::Ext::Disco->new);
	#$con->add_extension (my $muc = AnyEvent::XMPP::Ext::MUC->new (disco => $disco));
	
	
	
	warn "Starting Connection";
	$con->start;
	
	$self->{connection} = $con;

	my $c = AnyEvent->condvar;
	$self->{condvar} = $c;
	
	
	
}

sub _register_xmpp_callbacks {
	my ($self,$con) = @_;
	warn "Register XMPP callbacks";
	$con->reg_cb(
		connected => \&on_connected,
		connect_error => \&on_connect_error,
		error => \&on_error,
		# added_account => \&on_added_account,
		# removed_account => \&on_removed_account,
		
		## MUC callbacks
		#message => \&on_receive_message,
	
		#enter => \&on_enter_channel,
		#leave => \&on_leave_channel,
		
		#join  => \&on_user_join,
		#part  => \&on_user_part,
		
		
	
	);
	
}

sub on_connected { warn "Connected , ", @_ }
sub on_connect_error { warn "ConnectError , ", @_ }

# client , account , Error::Exception
sub on_error { 
	my ($client,$account,$error) = @_;
	
	warn "Error, ", $error->string, ' - ' , $error->context;


}

sub shutdown {
	my $self = shift;
	$self->connection->disconnect;
	
}

sub poll {
	warn "Polled"
}

sub tell_channel {}

sub receive_from_channel {}


sub on_receive_message {
	
}

1;
