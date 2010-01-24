package Padre::Plugin::Swarm;

use 5.008;
use strict;
use warnings;
use File::Spec             ();
use Padre::Constant        ();
use Padre::Wx              ();
use Padre::Plugin          ();
use Padre::Wx::Icon        ();
use Padre::Service::Swarm  ();
use Padre::Swarm::Geometry ();
use Padre::Wx::Swarm::Chat ();
#use Padre::Plugin::Swarm::Wx::Resources ();
use Padre::Plugin::Swarm::Wx::Editor ();


use Class::XSAccessor 
	accessors => {
		geometry => 'geometry',
		resources=> 'resources',
		editor   => 'editor',
		chat     => 'chat',
		config   => 'config',
	};
	
use Wx::Socket ();

our $VERSION = '0.07';
our @ISA     = 'Padre::Plugin';

# The padre multicast group (unofficial)
my $WxSwarmAddr = Wx::IPV4address->new;
$WxSwarmAddr->SetHostname('239.255.255.1');
$WxSwarmAddr->SetService(12000);

# Local address 
my $WxLocalAddr = Wx::IPV4address->new;
$WxLocalAddr->SetAnyAddress;
$WxLocalAddr->SetService( 0 );





SCOPE: {
  my $SOCK_SEND;
  my $EVT_RECV;
  my $EVT_SWARM_RECV ;
  my $SERVICE;
  sub connect {
	my $self = shift;

	my $listen_service = Padre::Service::Swarm->new;
	$listen_service->schedule;
	$EVT_RECV = $listen_service->event;
	$SERVICE = $listen_service;
	$SOCK_SEND = Wx::DatagramSocket->new( $WxLocalAddr );
	$EVT_SWARM_RECV = Wx::NewEventType;

	#EVT_SOCKET_INPUT($self->main , $sock , \&onConnect ) ;
	Wx::Event::EVT_COMMAND(
		Padre->ide->wx->main,
		-1,
		$EVT_RECV,
		sub { $self->accept_message(@_) }
	);
	

	
  }
  
  sub disconnect {
  	my $self = shift;
  	
  	
  	$SERVICE->tell('HANGUP');
  	$self->send( {type=>'leave'} );
  	undef $EVT_RECV;
  	undef $SOCK_SEND;
  	undef $EVT_SWARM_RECV;
  	
  	
  }

sub event { $EVT_RECV }
sub message_event { $EVT_SWARM_RECV }

sub send {
	return unless $SOCK_SEND;
	shift->_send(@_);
}

sub _send {
	my $self = shift;
	my $message = shift;
	$message->{from} = $self->identity->nickname;
	my $data =  $SERVICE->marshal->encode( $message );
	$SOCK_SEND->SendTo($WxSwarmAddr, $data, length($data) );
	
}


}

sub accept_message { 
	my ($self,$main,$event) = @_;
	
	my $data = $event->GetData;
	if ( $data eq 'ALIVE' ) {
		$self->send(
			{ type=>'announce', service=>'swarm' }
		);
		$self->send(
		{ type=>'disco', service=>'swarm' }
		);
		return;
	}
	my $message = eval {  Storable::thaw( $data ); };
	
	my $handler = 'accept_' . $message->type;
	if ( $self->can( $handler ) ) {
		eval { $self->$handler( $message ); };
	}
	$self->geometry->On_SwarmMessage( $message );
	
	Wx::PostEvent(
                $main,
                Wx::PlThreadEvent->new( -1, $self->message_event , $data ),
        ) if $self->message_event;
}

sub accept_disco {
	my ($self,$message) = @_;
	$self->send( {type=>'promote',service=>'swarm'} );
	
}



sub identity {
	my $config = Padre::Config->read;
	my $nickname = $config->identity_nickname;
	unless ( $nickname ) {
		$nickname = "Anonymous_$$";
	}
	Padre::Swarm::Identity->new( 
		nickname => $nickname,
		service => 'swarm',
	);
}








#####################################################################
# Padre::Plugin Methods

sub padre_interfaces {
	'Padre::Plugin' => 0.51;
}

sub plugin_name {
	'Swarm';
}

sub plugin_icons_directory {
	my $dir = File::Spec->catdir(
		shift->plugin_directory_share(@_),
		'icons',
	);
	$dir;
}

sub plugin_icon {
	my $class = shift;
	Padre::Wx::Icon::find( 
		'status/padre-plugin-swarm',
		{ icons => $class->plugin_icons_directory },
	);
}

sub menu_plugins_simple {
    my $self = shift;
    return $self->plugin_name => [
        'Run in Other Editor' => 
            sub { $self->run_in_other_editor },
        'Open in Other Editor' => 
            sub { $self->open_in_other_editor },
            
        'About' => sub { $self->show_about },
    ];
}

# Singleton (I think)
SCOPE: {
	my $instance;

	sub instance { $instance };

	sub plugin_enable {
		require Padre::Wx::Swarm::Chat;
		my $self   = shift;
		$instance  = $self;
		my $config = $self->config_read;
		$self->config( $config );
		
		$self->geometry( Padre::Swarm::Geometry->new );
		$self->connect();
		
		$self->editor( Padre::Plugin::Swarm::Wx::Editor->new );
		$self->editor->enable;
		
		my $chat = Padre::Wx::Swarm::Chat->new( $self->main );
		$chat->enable;
		$self->chat( $chat );
#		my $directory = Padre::Plugin::Swarm::Wx::Resources->new(
#			$self->main
#		);
#		$self->resources( $directory );
#		$directory->enable;
		
		1;
	}

	sub plugin_disable {
		my $self = shift;
		$self->chat->disable;
		$self->chat(undef);
		
		$self->editor->disable;
		$self->editor(undef);
		
#		$self->resources->disable;
#		$self->resources(undef);
	
		$self->disconnect;
	
		undef $instance;
	
		
	}
}

sub editor_enable {
	my $self = shift;
	$self->editor->editor_enable(@_);
}

sub editor_disable {
	my $self = shift;
	$self->editor->editor_disable(@_);
}

# oh noes!
sub run_in_other_editor {
    my $self = shift;
    my $ed = $self->current->editor;
    my $doc = $self->current->document;
    $self->send(
        Padre::Swarm::Message->new(
            type => 'runme',
            body => $ed->GetText,
            filename => $doc->filename,
        )
    );
    
}

sub open_in_other_editor {
    my $self = shift;
    my $doc = $self->current->document;
    my $message = Padre::Swarm::Message->new(
        type => 'openme',
        body => $doc->text_get,
        filename => $doc->filename,
    );
    $self->send($message);
    
}

sub show_about {
	my $self = shift;

	# Generate the About dialog
	my $icon  = Padre::Wx::Icon::find(
		'status/padre-plugin-swarm',
		{
			size  => '128x128',
			icons => $self->plugin_icons_directory,
		} 
	);

	my $about = Wx::AboutDialogInfo->new;
	$about->SetName('Swarm Plugin');
	$about->SetDescription( <<"END_MESSAGE" );
Surrender to the Swarm!
END_MESSAGE
	$about->SetIcon( Padre::Wx::Icon::cast_to_icon($icon) );

	# Show the About dialog
	Wx::AboutBox($about);

	return;
}


# Copyright 2008-2010 The Padre development team as listed in Padre.pm.
# LICENSE
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl 5 itself.

1;

__END__

=pod

=head1 NAME

Padre::Plugin::Swarm - Experimental plugin for collaborative editing

=head1 DESCRIPTION

This is Swarm!

Swarm is a Padre plugin for experimenting with remote inspection,
peer programming and collaborative editing functionality.

Within this plugin all rules are suspended. No security, no efficiency,
no scalability, no standards compliance, remote code execution,
everything is allowed. The only goal is things that work, and things
that look shiny in a demo :)

Lessons learned here will be applied to more practical plugins later.

=head1 COPYRIGHT

Copyright 2009 The Padre development team as listed in Padre.pm

=head1 LICENSE

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
