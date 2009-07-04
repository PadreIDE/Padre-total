#!/usr/bin/perl
use strict;
use warnings;
use lib qw( lib );
use Net::Jabber;
use Net::XMPP::Debug;
use Data::Dumper;
use Net::Jabber::Client;
use JSON::XS;
use Padre::Swarm::Transport::Multicast;


use constant MUC => 'padre_muc@conference.jabber.org';
use constant MUCPASS => 'szabgab';

my $resource = 'Padre-Swarm-' . $$;

my $padre = Padre::Swarm::Transport::Multicast->new;
$padre->subscribe_channel( 12000 , 1);
$padre->start;


my ($user,$pass) = @ARGV;
my ($username,$host) = split /@/, $user;

my $jid = $user . '/' . $resource;

my $mucjid;

my $xc = Net::Jabber::Client->new(debug=>2);
my $Debug = new Net::XMPP::Debug();
$Debug->Init(level=>1,file=>"stdout");
#$xc->{DEBUG} = $Debug;

$xc->SetCallBacks(
	onconnect=>\&connected,
	ondisconnect=> \&disconnected,
	onauth => \&authenticated,
	onprocess=>\&checkpadre,
	);
	
$xc->SetMessageCallBacks(
	normal=>\&chat,
	chat=> \&chat,
	groupchat => \&chat,
	#subscribe => \&negotiate,
); 



warn "execute";
$xc->Execute(
	hostname=>$host,
        username=>$username,
        password=>$pass,
        resource=>$resource,
	processtimeout=>0.5,
);
warn "execute completed";


#$xc->Connect( hostname => $host );
#$xc->AuthSend( username => $username, password=>$pass,
#	resource => 'padre-swarm-$$',
#);




sub connected {
	warn 'connected';
}

sub chat {
	my ($id,$msg) = @_;
	
	return if (
		$msg->GetSubject eq $jid );
		
warn "Tell padre from $jid ", $msg->GetSubject;
	$padre->tell_channel( 12000 ,
		JSON::XS::encode_json(
			{ user=>$msg->GetFrom, 
			message=>$msg->GetBody,
			subject=>$jid,
			thread=>$msg->GetThread,
			timestamp=>$msg->GetTimeStamp,
			}
		)
	)
}

sub checkpadre {
	if (my @ready = $padre->poll(0)) {
		my ($payload,$frame) = $padre->receive_from( 12000 );
		
		my $message = JSON::XS::decode_json( $payload );

			warn Dumper $message;
		# Dont loop :)
		return if ( exists $message->{subject}
			&& $message->{subject} eq $jid );
                
		my $jid = $xc->MessageSend(
			to=> MUC ,
			from => $mucjid,
                        subject=>$jid ,
                        thread=>$jid,
                        body => $message->{message},
			type => 'groupchat',
                );
                warn "Relayed PADRE chat as $jid";
	}
	
}

sub authenticated {
	warn 'authenticated';
	warn 'Joining MUC' ,
	my ($room,$server) = split /@/ , MUC;;
	$mucjid = $xc->MUCJoin(
		room => $room,
		password => MUCPASS,
		server => $server,
		nick => getlogin ."-$$" ,
	);
  
	
}


sub disconnected {
	warn $xc->GetErrorCode;
}


sub negotiate { die "BOINK!" }

