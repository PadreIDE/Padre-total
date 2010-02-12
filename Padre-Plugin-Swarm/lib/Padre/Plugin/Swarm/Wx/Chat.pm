package Padre::Plugin::Swarm::Wx::Chat;

use 5.008;
use strict;
use warnings;
use Text::Patch ();
use Params::Util qw{_INSTANCE};
use Wx::Perl::Dialog::Simple;

use Padre::Current qw{_CURRENT};
use Padre::Logger;
use Padre::Wx ();
use Padre::Config ();
use Padre::Plugin::Swarm ();
use Padre::Service::Swarm;
use Padre::Swarm::Identity;
use Padre::Swarm::Message;
use Padre::Swarm::Message::Diff;
use Padre::Util;
our $VERSION = '0.09';
our @ISA     = 'Wx::Panel';

use Class::XSAccessor
	accessors => {
		task      => 'task',
		service   => 'service',
		textinput => 'textinput',
		chatframe => 'chatframe',
		userlist  => 'userlist',
		users => 'users',
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
	
	my $userlist = Wx::ListView->new(
		$self, -1 ,
                Wx::wxDefaultPosition,
                Wx::wxDefaultSize,
                Wx::wxLC_REPORT | Wx::wxLC_SINGLE_SEL
        );
        $userlist->InsertColumn( 0, 'Users' );
        $userlist->SetColumnWidth( 0, -1 );
	$self->userlist($userlist);
	
	$hbox->Add( $chat , 1 , Wx::wxGROW );
	$hbox->Add( $userlist, 0 , Wx::wxGROW );
	
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
	TRACE( " main window is " . $self->main ) if DEBUG;
	TRACE( " message event is " . $self->plugin->message_event ) if DEBUG;	
	Wx::Event::EVT_COMMAND(
		$self->plugin->wx,
		-1,
		$self->plugin->message_event,
		sub { $self->accept_message(@_) }
	);
	# Add ourself to the gui;
	my $main     = $self->main;
	my $bottom   = $self->bottom;
	my $position = $bottom->GetPageCount;
	
	$self->update_userlist;
	
	my $pos = $bottom->InsertPage( $position, $self, gettext_label(), 0 );
	$self->Show;
	my $icon = $self->plugin->plugin_icon;  
	$bottom->SetPageBitmap($position, $icon );
	$bottom->SetSelection($position);
	$self->textinput->SetFocus;
	$main->aui->Update;

	$self->{enabled} = 1;
}

sub disable {
	my $self = shift;
	TRACE( 'Disable Chat' ) if DEBUG;
	my $main = $self->main;
	my $bottom= $self->bottom;
	my $position = $bottom->GetPageIndex($self);
	$self->Hide;


	$bottom->RemovePage($position);
	$main->aui->Update;
	$self->Destroy;
}

sub update_userlist {
	my $self = shift;
	my $userlist = $self->userlist;
	my $geo = $self->plugin->geometry;
	my @users = $geo->get_users();
	$userlist->DeleteAllItems;
	foreach my $user ( @users ) {
		my $item = Wx::ListItem->new( );
		$item->SetText( $user );
		$item->SetTextColour( 
			Wx::Colour->new( @{ derive_rgb($user) } )  
		);
		$userlist->InsertItem( $item );
	}
	$userlist->SetColumnWidth( 0, -1 );
	
}

sub accept_message {
	my $self = shift;
	my $main = shift;
	my $evt = shift;

	my $payload = $evt->GetData;
	$evt->Skip(1);

	my $message = Storable::thaw($payload);
	return unless _INSTANCE( $message , 'Padre::Swarm::Message' );
        my $handler = 'accept_' . $message->type;
	TRACE( $handler ) if DEBUG;
        if ( $self->can( $handler ) ) {
        	TRACE( $message->{from} . ' sent ' . $message->{type} ) if DEBUG;
            eval {
                $self->$handler($message);
            };
            if ($@) {
                $self->write_user_styled( $message->from,$message->from );
                $self->write_unstyled(" sent unhandled message " 
                    . $message->type .  $@ . "\n" );
                    
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
        return;
    }
    else {
        $self->write_user_styled( $announce->from , $announce->from );
        $self->write_unstyled(  " has joined the swarm \n" );
        $self->users->{$nick} = 1;
    }
     $self->update_userlist;
    
}

sub accept_promote {
    my ($self,$message) = @_;
    
    ## Todo - manipulate the geometry ourselves for
    # 'chat' promote. stop spewing into the chat 
    # console.
    if ( $message->{service} eq 'chat' ) {
	$self->update_userlist;
    }
    
    
}

sub accept_disco {
	my ($self,$message) = @_;
	$self->plugin->send( {type=>'promote',service=>'chat'} );
}

sub accept_leave {
    my ($self,$message) = @_;
    my $identity = $message->from;
    delete $self->users->{$identity};
    $self->write_user_styled( $identity , $identity );
    $self->write_unstyled( " has left the swarm.\n" );
    $self->update_userlist;
}


sub command_nick {
    my ($self,$new_nick) = @_;
    my $previous =
            $self->plugin->identity->nickname;
        eval {
            $self->plugin->identity->set_nickname($new_nick);
            my $config = Padre::Config->read;
            $config->set( identity_nickname => $new_nick );
            $config->write;
        };

	warn $@ if $@;
	
        $self->tell_service( 
            "was -> ".
            $previous	
        ) unless $@;
    
}

sub command_disco {
    my $self = shift;
    $self->plugin->send({type=>'disco'});
}


sub tell_service {
	my $self    = shift;
	my $body    = shift;
	my $args    = shift;
	my $message = _INSTANCE($body,'Padre::Swarm::Message')
		? $body
		: Padre::Swarm::Message->new(
			body => $body,
			type => 'chat',
		);
	$self->plugin->send($message)
}

sub on_text_enter {
    my ($self,$event) = @_;
    my $message = $self->textinput->GetValue;
    $self->textinput->SetValue('');
    
    if ( $message =~ m{^/(\w+)} ) {
        $self->accept_command( $message ) 
    }    
    else {
        $self->tell_service( $message );
    }
}

sub accept_command {
    my ($self,$message) = @_;
    $message =~ s|/||;
    # Handle /nick for now so everyone is not Anonymous_$$
    my ($command,$data) = split /\s/ , $message ,2 ;
    
    my $handler = 'command_' . $command;
    if ( $self->can( $handler ) ) {
	$self->$handler($data);
    	
    } else { $self->tell_service( $message ); }
    
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
