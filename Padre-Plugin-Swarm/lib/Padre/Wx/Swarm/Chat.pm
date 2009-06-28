package Padre::Wx::Swarm::Chat;

use 5.008;
use strict;
use warnings;
use Params::Util qw{_INSTANCE};
use Padre::Wx ();
use Padre::Task::Buzz;
use Class::Autouse;

our $VERSION = '0.37';
our @ISA     = 'Wx::Panel';

#our $EVT_Chat = Wx::NewEventType();
use Class::XSAccessor
	accessors => {
		task => 'task',
		service=>'service',
		textinput => 'textinput',
		chatframe => 'chatframe',
	},
	setters => { 'set_task' => 'task' };
	
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
	
	my $task_push_event : shared = Wx::NewEventType();
	
	
	my $service = Padre::Swarm::Service::Chat->new;
	
	my $service_task = Padre::Task::Buzz->new(
		service => 'Padre::Swarm::Service::Chat', 
		task_event => $task_push_event,
		#main_thread_only => sub { $self->service_quit }
	);
	$self->set_task( $service_task );
	$self->{service} = $service;
	$service->start;
	# Set up the event handler, we will 
	# ->accept_message when the task loop ->post_event($data)
	#  to us.
	Wx::Event::EVT_COMMAND(
		Padre->ide->wx->main,
		-1,
		$task_push_event,
		sub { $self->accept_message(@_) }
	);
	# Add ourself to the gui;
	my $main     = $self->main;
	my $bottom   = $self->bottom;
	my $position = $bottom->GetPageCount;
	$bottom->InsertPage( $position, $self, gettext_label(), 0 );
	$self->Show;
	$bottom->SetSelection($position);
	$main->aui->Update;
	$self->task->schedule;
	$self->{enabled} = 1;
}

sub disable {
	my $self = shift;
	my $main = $self->main;
	my $bottom= $self->bottom;
	my $position = $bottom->GetPageIndex($self);
	$self->Hide;
	$self->task->running( 0 );
	$bottom->RemovePage($position);
	$main->aui->Update;
	$self->Destroy;
}

sub accept_message {
	my $self = shift;

	my $main = shift;
	my $evt = shift;
	
	my $message = Storable::thaw( $evt->GetData );
	my $user = $message->{user} || 'unknown';
	my $ip   = $message->{client_address} || 'unknown';
	my $content = $message->{message};
	return unless defined $content;
	my $output = sprintf( "%s@[%s] :%s\n", $user, $ip, $content );
	$self->chatframe->AppendText( $output );

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

