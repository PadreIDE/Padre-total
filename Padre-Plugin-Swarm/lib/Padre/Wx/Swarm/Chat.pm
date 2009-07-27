package Padre::Wx::Swarm::Chat;

use 5.008;
use strict;
use warnings;
use Text::Patch ();
use Params::Util qw{_INSTANCE};
use Wx::Perl::Dialog::Simple;
use Padre::Current qw{_CURRENT};
use Padre::Wx ();
use Padre::Config ();
use Padre::Service::Swarm;
use Padre::Swarm::Identity;
use Padre::Swarm::Message;
use Padre::Swarm::Message::Diff;
use Padre::Swarm::Service::Chat;

our $VERSION = '0.01';
our @ISA     = 'Wx::Panel';

use Class::XSAccessor
	accessors => {
		task      => 'task',
		service   => 'service',
		textinput => 'textinput',
		chatframe => 'chatframe',
	},
	setters => {
		'set_task' => 'task',
	};

sub new {
	my $class = shift;
	my $main  = shift;
	my $self = $class->SUPER::new(
		$main->bottom, -1,
		#'',
		Wx::wxDefaultPosition,
		Wx::wxDefaultSize,
		Wx::wxLC_REPORT
		| Wx::wxLC_SINGLE_SEL
	);

	# build large area for chat output , with a 
	#  single line entry widget for input
	my $sizer = Wx::BoxSizer->new(Wx::wxVERTICAL);
	
	my $text = Wx::TextCtrl->new(
		$self, -1, '',
		Wx::wxDefaultPosition,
		Wx::wxDefaultSize,
		Wx::wxTE_PROCESS_ENTER
	);
	my $chat = Wx::TextCtrl->new(
		$self, -1, '',
		Wx::wxDefaultPosition,
		Wx::wxDefaultSize,
		Wx::wxTE_READONLY
		| Wx::wxTE_MULTILINE
		| Wx::wxNO_FULL_REPAINT_ON_RESIZE
	);
	$sizer->Add($chat,1, Wx::wxGROW );
	$sizer->Add($text,0, Wx::wxGROW );

	$self->textinput( $text );
	$self->chatframe( $chat );
	$self->SetSizer($sizer);

	my $config = Padre::Config->read;
	my $nickname = $config->identity_nickname;
	unless ( $nickname ) {
		$nickname = "Anonymous_$$";
	}

	my $identity = Padre::Swarm::Identity->new(
		nickname => $nickname,
		service  => 'chat',
		resource => 'Padre',
	);

	my $service = Padre::Swarm::Service::Chat->new(
		identity      => $identity,
		use_transport => {
			#'Padre::Swarm::Transport::Multicast'=>{
			'Padre::Swarm::Transport::IRC' => {
				identity => $identity,
				loopback => 1,
			},
		}
	);
	$self->service( $service );

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
	Padre::Util::debug( "Enable Chat" );
	$self->service->schedule;
	# Set up the event handler, we will 
	# ->accept_message when the task loop ->post_event($data)
	#  to us.
	Wx::Event::EVT_COMMAND(
		Padre->ide->wx->main,
		-1,
		$self->service->event,
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

	$self->{enabled} = 1;
}

sub disable {
	my $self = shift;
	Padre::Util::debug( 'Disable Chat' );
	my $main = $self->main;
	my $bottom= $self->bottom;
	my $position = $bottom->GetPageIndex($self);
	$self->service->tell('HANGUP');
	
	$self->Hide;
	

	$bottom->RemovePage($position);
	$main->aui->Update;
	$self->Destroy;
}

sub accept_message {
	my $self = shift;
	my $main = shift;
	my $evt = shift;

	my $payload = $evt->GetData;
	# Hack - the alive should be via service poll event ?
	return if $payload eq 'ALIVE';
	
	my $message = Storable::thaw($payload);
	#my $message = $evt->GetData;
	return unless _INSTANCE( $message , 'Padre::Swarm::Message' );

	if ( $message->type eq 'chat' ) {
		my $user = $message->from || 'unknown';
		my $content = $message->body;
		return unless defined $content;
		my $output = sprintf( "%s :%s\n", $user, $content );
		$self->chatframe->AppendText( $output );
	}
	elsif ( _INSTANCE( $message , 'Padre::Swarm::Message::Diff' ) ) {
		$self->on_receive_diff($message);
		return;
	}
	else {
		warn "Discarded $message";
	}
}

sub tell_service {
	my $self    = shift;
	my $body    = shift;
	my $args    = shift;
	my $message = _INSTANCE($body,'Padre::Swarm::Message')
		? $body
		: Padre::Swarm::Message->new(
			body => $body,
			from => $self->service->identity->nickname,
		);

	my $service = $self->service->tell($message) 
}

sub on_text_enter {
	my ($self,$event) = @_;
	my $message = $self->textinput->GetValue;
	$self->tell_service( $message );
	$self->textinput->SetValue('');
}

sub on_receive_diff {
	my ($self,$message) = @_;
	warn "Received diff $message";
	
	my $project = $message->project;
	my $file = $message->file;
	my $diff = $message->diff;
	
	my $current = $self->main->current->document;
	my $editor = $self->main->current->editor;
	
	my $p_dir = $current->project_dir;
	my $p_name = File::Basename::basename( $p_dir );
	my $p_file = $current->filename;
	$p_file =~ s/^$p_dir//;
	
	warn "Have current doc $p_file, $p_name";
	return unless $p_dir;
	return unless ( $p_name eq $project );
	
	# Ignore my own diffs
	if ( $message->from eq $self->service->identity->nickname ) {
		warn "Ignore my own diffs";
		return;
	}
	
	Wx::Perl::Dialog::Simple::dialog( 
		sub {},
		sub {},
		sub {},
		{ title => 'Swarm Diff' }
	);
	warn "PAtching $file in $project";
	warn "APPLY PATCH \n" . $diff;
	eval {
		my $result = Text::Patch::patch( $current->text_get , $diff , STYLE=>'Unified' );
		$editor->SetText( $result );
	};
	
	warn $@ if $@;
}

sub on_diff_snippet {
	my ($self) = @_;
	my $document = _CURRENT->document or return;
	my $text = $document->text_get;
	my $file = $document->filename;
	unless ($file) {
		return;
	}
	my $canonical_file = $file;
	
	#my $project = $document->project;
	
	my $project_dir = $document->project_dir;
	my $project_name = File::Basename::basename( $project_dir );
	$canonical_file =~ s/^$project_dir//;
	
	my $message = Padre::Swarm::Message::Diff->new({
		file     => $canonical_file,
		project  => $project_name,
		project_dir => $project_dir,
		type => 'diff',
	});

	my $external_diff = $self->main->config->external_diff_tool;
	if ($external_diff) {
		my $dir = File::Temp::tempdir( CLEANUP => 1 );
		my $filename = File::Spec->catdir( $dir, 'IN_EDITOR' . File::Basename::basename($file) );
		if ( open my $fh, '>', $filename ) {
			print $fh $text;
			CORE::close($fh);
			system( $external_diff, $filename, $file );
		} else {
			warn $!;
			#$self->main->errorlist->AppendTe($!);
		}

		# save current version in a temp directory
		# run the external diff on the original and the launch the
	} else {
		require Text::Diff;
		my $diff = Text::Diff::diff( $file, \$text );
		unless ($diff) {
			#$self->main->errorlist->Append( Wx::gettext("There are no differences\n") );
			return;
		}
		$message->{diff} = $diff;
	}
	
	$self->tell_service( $message );
	return;
}

1;
