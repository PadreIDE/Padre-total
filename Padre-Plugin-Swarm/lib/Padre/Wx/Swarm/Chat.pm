package Padre::Wx::Swarm::Chat;

use 5.008;
use strict;
use warnings;
use Params::Util qw{_INSTANCE};
use Padre::Wx ();

our $VERSION = '0.37';
our @ISA     = 'Wx::TextCtrl';

#our $EVT_Chat = Wx::NewEventType();

sub new {
	my $class = shift;
	my $main  = shift;
	my $self = $class->SUPER::new(
		$main->bottom,-1,
		'',
		Wx::wxDefaultPosition,
		Wx::wxDefaultSize,
		Wx::wxLC_REPORT | Wx::wxLC_SINGLE_SEL
	);
	return $self;
}

sub bottom {
	$_[0]->GetParent;
}

sub main {
	$_[0]->GetGrandParent;
}

	
sub gettext_label {
	Wx::gettext('Swarm - Chat');
}

sub enable {
	my $self     = shift;
	my $main     = $self->main;
	my $bottom   = $self->bottom;

#	Wx::Event::EVT_COMMAND(
#		$self,
#		-1,
#		$EVT_Chat,
#		\&on_chat_received,
#	);
#	
# brutal polling , proper events later.
	my $timer = Wx::Timer->new( $self, -1 );
	Wx::Event::EVT_TIMER(
		$self,
		-1,
		sub { shift->poll_service(@_) },
	);
	$timer->Start( 1000, 0 );
	$self->{timer} = $timer;


	my $position = $bottom->GetPageCount;
	$bottom->InsertPage( $position, $self, gettext_label(), 0 );
	$self->Show;
	$bottom->SetSelection($position);
	$main->aui->Update;
	$self->{enabled} = 1;
}

sub disable {
	my $self = shift;
	my $main = $self->main;
	my $bottom= $self->bottom;
	my $position = $bottom->GetPageIndex($self);
	$self->Hide;
	$bottom->RemovePage($position);
	$main->aui->Update;
	$self->Destroy;
	$self->{timer}->Destroy;
	delete $self->{timer};
}

sub poll_service {
	my $self = shift;
	my $main = $self->main;
	my $swarm = $main->ide->plugin_manager->plugins->{Swarm}->object;
	if (my $message = $swarm->get_services->{chat}->receive) {
		my $user = $message->{user} || 'unknown';
		my $ip   = $message->{client_address} || 'unknown';
		my $content = $message->{message};
		my $output = sprintf( "%s@[%s] :%s\n",
			$user, $ip, $content
		);
		$self->AppendText( $output . "\n" );
	}
}
1;

