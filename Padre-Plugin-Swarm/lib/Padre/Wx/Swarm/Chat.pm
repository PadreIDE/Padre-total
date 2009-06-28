package Padre::Wx::Swarm::Chat;

use 5.008;
use strict;
use warnings;
use Params::Util qw{_INSTANCE};
use Padre::Wx ();

our $VERSION = '0.37';
our @ISA     = 'Wx::Panel';

#our $EVT_Chat = Wx::NewEventType();
use Class::XSAccessor
	accessors => {
		textinput => 'textinput',
		chatframe => 'chatframe',
	};
	
sub new {
	my $class = shift;
	my $main  = shift;
	my $self = $class->SUPER::new(
		$main->bottom,-1,
		#'',
		Wx::wxDefaultPosition,
		Wx::wxDefaultSize,
		Wx::wxLC_REPORT | Wx::wxLC_SINGLE_SEL
	);
	
	my $sizer = Wx::BoxSizer->new(Wx::wxVERTICAL);
	
	my $text = Wx::TextCtrl->new($self,-1,'',
		Wx::wxDefaultPosition,
		Wx::wxDefaultSize,
		Wx::wxTE_PROCESS_ENTER
	);
	my $chat = Wx::TextCtrl->new($self,-1,'',
		Wx::wxDefaultPosition,
		Wx::wxDefaultSize,
		Wx::wxTE_READONLY|Wx::wxTE_MULTILINE|Wx::wxNO_FULL_REPAINT_ON_RESIZE
	);
	$sizer->Add($chat,1, Wx::wxGROW );
	$sizer->Add($text,0, Wx::wxGROW );
	
	$self->textinput( $text );
	$self->chatframe( $chat );
	$self->SetSizer($sizer);
	
	Wx::Event::EVT_TEXT_ENTER(
                $self, $text,
                \&on_text_enter
        );

	
	return $self;
}

sub service {
	my $self = shift;
	# Crikey!
	$self->main->ide
		->plugin_manager->plugins
			->{Swarm}->object
				->get_services->{chat};
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
	my $service = $self->service;
	if (my $message = $service->receive) {
		my $user = $message->{user} || 'unknown';
		my $ip   = $message->{client_address} || 'unknown';
		my $content = $message->{message};
		return unless $content;
		my $output = sprintf( "%s@[%s] :%s\n",
			$user, $ip, $content
		);
		$self->chatframe->AppendText( $output );
	}
}

sub tell_service {
	my $self = shift;
	my $body = shift;
	my $args = shift;
	my $service = $self->service;
	$service->chat( $body );
	
}

sub on_text_enter {
	my ($self,$event) = @_;
	my $message = $self->textinput->GetValue;
	$self->tell_service( $message );
	$self->textinput->SetValue('');
	
}
1;

