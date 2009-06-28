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

my $padre = Padre::Swarm::Transport::Multicast->new;
$padre->subscribe_channel( 12000 , 1 );
$padre->start;


my ($user,$pass) = @ARGV;
my ($username,$host) = split /@/, $user;

my $xc = Net::Jabber::Client->new();
$xc->SetCallBacks(
	onconnect=>\&connected,
	ondisconnect=> \&disconnected,
	onauth => \&authenticated,
	);
	
$xc->SetMessageCallBacks(
	normal=>\&chat,
	chat=> \&chat,
	groupchat => \&chat,
	#subscribe => \&negotiate,
); 


$xc->Execute(
	hostname=>$host,
        username=>$username,
        password=>$pass,
        resource=>"Padre-Swarm-$$",
        mode => 'nonblock',
);
#

while (defined $xc->Process(5) ) {
	warn "loop";
}


sub connected {
	warn 'connected';
}

sub chat {
	my ($jid,$msg) = @_;
	warn "CHAT handed $jid ";
	warn $msg->GetBody;
	
	

warn "Tell padre " ,
	$padre->tell_channel( 12000 ,
		JSON::XS::encode_json(
			{ user=>$msg->GetFrom, 
			message=>$msg->GetBody,
			subject=>$msg->GetSubject,
			timestamp=>$msg->GetTimeStamp}
		)
	)
}


sub authenticated {
	warn 'authenticated';
	warn 'Joining MUC' ,
	$xc->MUCJoin(
		room => 'padre_muc',
		password => 'szabgab',
		server => 'conference.jabber.org',
		nick => 'padre-swarm-xmpp-test',
	);
  
	
}


sub disconnected {
	warn $xc->GetErrorCode;
}


sub negotiate { die "BOINK!" }

