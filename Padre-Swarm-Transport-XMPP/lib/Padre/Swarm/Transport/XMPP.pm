package Padre::Swarm::Transport::XMPP;

use strict;
use warnings;

use Padre::Swarm::Transport;
our @ISA = 'Padre::Swarm::Transport';

use Net::Jabber;
use Net::XMPP::Debug;
use Data::Dumper;
use Net::Jabber::Client;
use Params::Util qw( _HASH );
use Class::XSAccessor
	accessors => {
		connection => 'connection',
		transport_id=>'transport_id',
		auth => 'auth',
		server => 'server',
		conference_server=>'conference_server',
	};


# Cheeky
use constant MUC => 'padre_muc@conference.jabber.org';
# fearless leader
use constant MUCPASS => 'szabgab';


sub new {
	my ($class,%args) = @_;
	my $auth = _HASH( delete $args{auth} );
	my $self = $class->SUPER::new( %args );
	
	my $resource = 'Padre-Swarm';
	my ($user,$pass) = @$auth{qw/ username password /};

	my ($username,$host) = split /@/, $user;
	$self->{server} = $host;
	
	my $transport_id = $user . '/' . $resource;

	
	my $xc = Net::Jabber::Client->new(debug=>1);
	my $Debug = new Net::XMPP::Debug();
	$Debug->Init(level=>1,file=>"stdout");
	$xc->{DEBUG} = $Debug;
	$xc->SetCallBacks(
		onconnect=> sub { $self->connected( username=>$username,password=>$pass,resource=>$resource  )},
		
		
		$self->cb(
			username => $username,
			password => $pass,
			resource => $resource,	
		)->connected,
		
		ondisconnect=> $self->cb()->disconnected,
		
		onauth => $self->cb(
		)->authenticated,
		
		onprocess=> $self->cb()->checkpadre,
	);


	$xc->SetMessageCallBacks(
		normal=>\&chat,
		chat=> \&chat,
		groupchat => \&chat,
		#subscribe => \&negotiate,
	); 


	$self->{connection} = $xc;
	$self->{transport_id}= $transport_id;
	
	return $self;
}


sub start {
	my ($self) = @_;
	my $xc = $self->connection;
	my $id = $self->transport_id;
	

	warn "Starting $xc";

	my $status = $xc->Connect(
		hostname=>$self->server,
		processtimeout=>0.5,
		tls => 0,
		
	);
	$self->{started} = $status;
	$xc->Execute;


}

sub shutdown {
	my $self = shift;
	$self->connection->Disconnect;
	
	
}

sub poll {
	my $self = shift;
	if ( my $status = $self->connection->Process(0.5) ) {
		warn "Data was processed!";
		
	}
	elsif ( defined $status ) {
		return;
	}
	else {
		die "Connection quit!";
	}
	
}
#$xc->Connect( hostname => $host );
#$xc->AuthSend( username => $username, password=>$pass,
#	resource => 'padre-swarm-$$',
#);

sub _connect_channel {
	my ($self,$channel) = @_;
	
	my $xc = $self->connection;
	my $room = 'padre_swarm_' . $channel;
	
	warn 'authenticated';
	warn 'Joining MUC ' . $room ;
	
	$xc->MUCJoin(
		room => $room,
		#password => $key,
		server => $self->conference_server,
		nick => $self->identity, 
	);	
}	

sub _shutdown_channel {
	my ($self,$channel) = @_;
	my $xc = $self->connection;
	my $room = 'padre_swarm_' . $channel;
	my $room_id = sprintf( '%s@%s/%s' ,
		$room , $self->conference_server, $self->identity,
	);
	$xc->PresenceSend( to => $room_id , status=>'unavailable' );
	
}

sub connected {
	my ($self,%args) = @_;
	warn "Send AUTH!";
	$self->connection->AuthSend(
		%args,
		'block' => undef,
	);
	
}


sub authenticated {
	my ($self,%args) = @_;
	my $xc = $self->connection;
}


sub disconnected {
	my $self = shift;
	my $xc = $self->connection;
	warn $xc->GetErrorCode;
	
}


sub receive_message {
	my ($self,$id,$msg) = @_;
	my $xc = $self->connection;
		
	warn "Tell padre from $id ", $msg->GetSubject;
	warn Dumper $msg;
	
	my %frame = (
		user=>$msg->GetFrom, 
		timestamp=>$msg->GetTimeStamp,
	);

	push @{ $self->{_incoming_buffer} } , [ $msg->GetBody, \%frame ] ;
}

sub tell_channel {
	my ($self,$channel,$payload) = @_;
	my $muc_channel = 'padre_swarm_' . $channel;
	my $xc = $self->connection;
	
	my $jid = $xc->MessageSend(
			to=> $muc_channel ,
                        body => $payload,
			type => 'groupchat',
                );
        warn "Relayed PADRE chat as $jid";

}

1;
