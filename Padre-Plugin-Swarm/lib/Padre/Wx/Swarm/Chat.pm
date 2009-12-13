package Padre::Wx::Swarm::Chat;

use 5.008;
use strict;
use warnings;
use Text::Patch ();
use Params::Util qw{_INSTANCE};
use Wx::Perl::Dialog::Simple;

use Padre::Current qw{_CURRENT};
use Padre::Debug;
use Padre::Wx ();
use Padre::Config ();
use Padre::Plugin::Swarm ();
use Padre::Service::Swarm;
use Padre::Swarm::Identity;
use Padre::Swarm::Message;
use Padre::Swarm::Message::Diff;
use Padre::Swarm::Service::Chat;
use Padre::Util;
our $VERSION = '0.06';
our @ISA     = 'Wx::Panel';

use Class::XSAccessor
	accessors => {
		task      => 'task',
		service   => 'service',
		textinput => 'textinput',
		chatframe => 'chatframe',
		users => 'users',
	},
	setters => {
		'set_task' => 'task',
	};
                
#use constant DEBUG => Padre::Plugin::Swarm::DEBUG;

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
        my $hbox = Wx::BoxSizer->new(Wx::wxHORIZONTAL);
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
	
	$hbox->Add( $chat , 1 , Wx::wxGROW );
	
	$sizer->Add($hbox,1, Wx::wxGROW );
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
			'Padre::Swarm::Transport::Multicast'=>{
				identity => $identity,
				loopback => 1,
			},
		}
	);
	$self->service( $service );
        $self->users( {} );
	Wx::Event::EVT_TEXT_ENTER(
                $self, $text,
                \&on_text_enter
        );

	return $self;
}

sub plugin { Padre::Plugin::Swarm->instance };

sub bottom {
	$_[0]->GetParent;
}

sub main {
	$_[0]->GetGrandParent;
}

sub gettext_label {
	Wx::gettext('Chat');
}

sub enable {
	my $self     = shift;
	TRACE( "Enable Chat" ) if DEBUG;
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
	my $pos = $bottom->InsertPage( $position, $self, gettext_label(), 0 );

    my $icon = $self->plugin->plugin_icon;  
	$bottom->SetPageBitmap($pos, $icon );
	
	$self->Show;
	$bottom->SetSelection($position);
	$main->aui->Update;

	$self->{enabled} = 1;
}

sub disable {
	my $self = shift;
	TRACE( 'Disable Chat' ) if DEBUG;
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
	warn "accepted $message" if DEBUG;
	return unless _INSTANCE( $message , 'Padre::Swarm::Message' );

        my $handler = 'accept_' . $message->type;
        if ( $self->can( $handler ) ) {
            eval {
                $self->$handler($message);
            };
            if ($@) {
                $self->write_user_styled( $message->from,$message->from );
                $self->write_unstyled(" sent unhandled message " 
                    . $message->type . "\n" );
                    
            }
        }

}

sub write_unstyled {
    my ($self,$text) = @_;
    my $style = $self->chatframe->GetDefaultStyle;
    $style->SetTextColour( Wx::Colour->new(0,0,0) );
    $self->chatframe->SetDefaultStyle($style);
    $self->chatframe->AppendText($text);
    
}

sub write_user_styled { 
    my ($self,$user,$text) = @_;
    my $style = $self->chatframe->GetDefaultStyle;
    my $rgb   = derive_rgb( $user );
    $style->SetTextColour( Wx::Colour->new(@$rgb) );
    $self->chatframe->SetDefaultStyle($style);
    $self->chatframe->AppendText($text);
}

sub accept_chat {
    my ($self,$message) = @_;
    $self->write_user_styled(
        $message->from,
        $message->from . ': '
    );
    $self->write_unstyled( $message->body . "\n" );
    
}

sub accept_announce {
    my ($self,$announce) = @_;
    my $nick = $announce->from;
    if ( exists $self->users->{$nick} ) {
        return
    }
    else {
        $self->write_user_styled( $announce->from , $announce->from );
        $self->write_unstyled(  " has joined the swarm \n" );
        $self->users->{$nick} = 1;
    }
    
}

sub accept_promote {
    my ($self,$message) = @_;
    return unless $message->{service} =~ m/chat/i;
    
    my $text = sprintf '%s promotes a chat service', $message->from;
    $self->write_user_styled( $message->from,  $text . "\n" );
    
}

sub accept_leave {
    my ($self,$message) = @_;
    my $identity = $message->from;
    $self->write_user_styled( $identity , $identity );
    $self->write_unstyled( " has left the swarm.\n" );
    
}

sub accept_runme {
    my ($self,$message) = @_;
    # Ouch..
    my @result = (eval $message->body);
    if ( $@ ) {
        $self->write_user_styled( $message->from , $message->from );
        $self->write_unstyled( ' ran' . $message->{filename}
            . ' in YOUR editor but failed!! ' . $@. "\n" );
    }
    else {
        $self->write_user_styled( $message->from , $message->from );
        $self->write_unstyled( ' ran ' . $message->{filename}
            . ' in YOUR editor successfully, returning '
            . join (', ' , @result)
            . "\n"
        );
        
    }
    
}

sub command_nick {
    my ($self,$new_nick) = @_;
    
    my $previous =
            $self->service->identity->nickname;	
        eval {
            $self->service->identity->set_nickname( $new_nick );
        };

        $self->tell_service( 
            "was -> ".
            $previous	
        ) unless $@;
    
}

sub command_spam {
    my ($self,$data) = @_;
    
    my $icon  = Padre::Wx::Icon::find(
        'status/padre-plugin-swarm',
        {
                size  => '128x128',
                icons => $self->plugin_icons_directory,
        } 
    );
    $icon->Show;
    
}

sub command_disco {
    
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
    $self->textinput->SetValue('');
    
    if ( $message =~ m{^/(\w+)\s+} ) {
        $self->accept_command( $message ) 
    }    
    else {
        $self->tell_service( $message );
    }
}

sub accept_command {
    my ($self,$message) = @_;
    # Handle /nick for now so everyone is not Anonymous_$$
    my ($command,$data) = $message =~ m{^/(\w+)\s+(.+)} ;
    if ( 'nick' eq $command ) {
        $self->command_nick( $data );
    } 
    elsif ( 'spam' eq $command ) {
        $self->command_spam( $data );
    }
    else { $self->tell_service( $message ); }
    
}

sub accept_diff {
	my ($self,$message) = @_;
	TRACE("Received diff $message") if DEBUG;

	my $project = $message->project;
	my $file = $message->file;
	my $diff = $message->diff;

	my $current = $self->main->current->document;
	my $editor = $self->main->current->editor;

	my $p_dir = $current->project_dir;
	my $p_name = File::Basename::basename( $p_dir );
	my $p_file = $current->filename;
	$p_file =~ s/^$p_dir//;

	TRACE("Have current doc $p_file, $p_name") if DEBUG;
	return unless $p_dir;
	return unless ( $p_name eq $project );

	# Ignore my own diffs
	if ( $message->from eq $self->service->identity->nickname ) {
		TRACE("Ignore my own diffs") if DEBUG;
		return;
	}

#	Wx::Perl::Dialog::Simple::dialog(
#		sub {},
#		sub {},
#		sub {},
#		{ title => 'Swarm Diff' }
#	);
	TRACE("Patching $file in $project") if DEBUG;
	TRACE("APPLY PATCH \n" . $diff) if DEBUG;
	eval {
		my $result = Text::Patch::patch( $current->text_get , $diff , STYLE=>'Unified' );
		$editor->SetText( $result );
	};

	if ( $@ ) {
		TRACE($@) if DEBUG;
	}
}

sub on_diff_snippet {
	my ($self) = @_;
	my $document = _CURRENT->document or return;
	my $text = $document->text_get;
	my $file = $document->filename;
	unless ( $file ) {
		return;
	}
	my $canonical_file = $file;

	#my $project = $document->project;

	my $project_dir = $document->project_dir;
	my $project_name = File::Basename::basename( $project_dir );
	$canonical_file =~ s/^$project_dir//;

	my $message = Padre::Swarm::Message::Diff->new(
		file        => $canonical_file,
		project     => $project_name,
		project_dir => $project_dir,
		type        => 'diff',
	);

	# Cargo from Padre somewhere ?
	my $external_diff = $self->main->config->external_diff_tool;
	if ( $external_diff ) {
		my $dir = File::Temp::tempdir( CLEANUP => 1 );
		my $filename = File::Spec->catdir( $dir, 'IN_EDITOR' . File::Basename::basename($file) );
		if ( open my $fh, '>', $filename ) {
			print $fh $text;
			CORE::close($fh);
			system( $external_diff, $filename, $file );
		} else {
			TRACE($!) if DEBUG;
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


## Try to style each identity differently


HSV2RGB: {
	my %vars;
	%vars = ( 
		h=>\my $h,
		s=>\my $s,
		v=>\my $v, 
		t=>\my $t,
		f=>\my $f,
		p=>\my $p,
		q=>\my $q,
	);
	my @matrix = (
		[$vars{v}, $vars{t}, $vars{p}],
		[$vars{q}, $vars{v}, $vars{p}],
		[$vars{p}, $vars{v}, $vars{t}],
		[$vars{p}, $vars{q}, $vars{v}],
		[$vars{t}, $vars{p}, $vars{v}],
		[$vars{v}, $vars{p}, $vars{q}],
	);
	
sub hsv2rgb {
	($h,$s,$v) = @_;
	my $h_index = ( $h / 60 ) % 6;
	
	$f = abs( $h/60 ) - $h_index;
	$p = $v * ( 1 - $s );
	$q = $v * ( 1 - ($f * $s));
	$t = $v * ( 1 - ( 1 - $f ) * $s );
	
	#$q = $v * ( 1 - $s * ($h 
	
	my $result = $matrix[$h_index];
	my @rgb = map { $$_ } @$result;
	return \@rgb;

}

}

use Digest::MD5 qw( md5 );
sub derive_rgb {
    my $string = shift;
    my $digest = md5($string);
    my $word   = substr($digest,0,2);
    my $int    = unpack('%S',$word);
    my $hue = 360 * ( $int / 65535 );
    my $norm =  hsv2rgb( $hue, 0.8, 0.75 );
    my @rgb =  map { int(255*$_) } @$norm;
    return \@rgb;
}




1;
