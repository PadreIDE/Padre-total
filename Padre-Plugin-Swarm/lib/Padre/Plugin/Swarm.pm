package Padre::Plugin::Swarm;

use 5.008;
use strict;
use warnings;
use File::Spec             ();
use Wx::Socket             ();
use Padre::Constant        ();
use Padre::Wx              ();
use Padre::Plugin          ();
use Padre::Wx::Icon        ();
use Padre::Swarm::Geometry ();
use Padre::Logger;

our $VERSION = '0.092';
our @ISA     = 'Padre::Plugin';

use Class::XSAccessor 
	accessors => {
		geometry => 'geometry',
		resources=> 'resources',
		editor   => 'editor',
		chat     => 'chat',
		config   => 'config',
		message_event => 'message_event',
		wx => 'wx',
		transport => 'transport',
	};
	


sub connect {
	my $self = shift;

	# For now - use global, 
	#  could be Padre::Plugin::Swarm::Transport::Local::Multicast
	#   based on preferences
	my $transport = 
	Padre::Plugin::Swarm::Transport::Global::WxSocket->new(
		wx => $self->wx,
		on_recv => sub { $self->on_recv(@_) } ,
		on_connect => sub { $self->on_transport_connect(@_) },
		on_disconnect => sub { $self->on_transport_disconnect(@_) }
	);
		
	$self->transport( $transport );
	$transport->enable;

	
}

sub disconnect {
	my $self = shift;

	$self->send( {type=>'leave'} );
	$self->transport->disable;
	$self->transport(undef);

}

sub send {
	my $self = shift;
	my $message = shift;
	my $mclass = ref $message;
	unless ( $mclass =~ /^Padre::Swarm::Message/ ) {
		bless $message , 'Padre::Swarm::Message';
	}
	$message->{from} = $self->identity->nickname;
	$self->transport->send( $message );
}

sub on_transport_connect {
	my ($self) = @_;
	
	TRACE( "Swarm transport connected" ) if DEBUG;
	$self->send(
		{ type=>'announce', service=>'swarm' }
	);
	$self->send(
		{ type=>'disco', service=>'swarm' }
	);
	return;
}

sub on_transport_disconnect {
	my ($self) = @_;
	TRACE( "Swarm transport disconnected" ) if DEBUG;
	
}


sub on_recv { 
	my $self = shift;
	my $message = shift;
	
	TRACE( "on_recv handler for " . $message->type ) if DEBUG;
	# TODO can i use 'SWARM' instead?
	my $lock = $self->main->lock('UPDATE'); 
	my $handler = 'accept_' . $message->type;
	
	if ( $self->can( $handler ) ) {
		TRACE( $handler ) if DEBUG;
		eval { $self->$handler( $message ); };
	}
	
	# TODO - make these parts use the message event! srsly
	$self->geometry->On_SwarmMessage( $message );
	
	#
	my $data = Storable::freeze( $message ); 
	Wx::PostEvent(
                $self->wx,
                Wx::PlThreadEvent->new( -1, $self->message_event , $data ),
        ) if $self->message_event;

}

sub accept_disco {
	my ($self,$message) = @_;
	$self->send( {type=>'promote',service=>'swarm'} );
}



sub identity {
	my $self = shift;
	unless ($self->{identity}) {
		my $config = Padre::Config->read;
		# Default to your padre nickname.
		my $nickname = $config->identity_nickname;
		#my $id = $$ . time(). $config . $self;
		
		unless ( $nickname ) {
			$nickname = "Anonymous_$$";
		}
		$self->{identity} = 
			Padre::Swarm::Identity->new( 
				nickname => $nickname,
				service => 'swarm',
			);
	}
	return $self->{identity};
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

sub plugin_large_icon {
	my $class = shift;
	my $icon  = Padre::Wx::Icon::find(
		'status/padre-plugin-swarm',
		{
			size  => '128x128',
			icons => $class->plugin_icons_directory,
		} 
	);
	return $icon;
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
	sub new { $instance = shift->SUPER::new(@_); }

	sub instance { $instance };

	sub plugin_enable {

		my $self   = shift;
		# TODO - enforce singleton!! 
		$instance  = $self;
		my $wxobj = new Wx::Panel $self->main;
		$self->wx( $wxobj );
		$wxobj->Hide;
		my $message_event  = Wx::NewEventType;
		$self->message_event($message_event);

		require Padre::Plugin::Swarm::Wx::Chat;
		require Padre::Plugin::Swarm::Wx::Resources;
		require Padre::Plugin::Swarm::Wx::Editor;
		require Padre::Plugin::Swarm::Wx::Preferences;
		require Padre::Plugin::Swarm::Transport::Global::WxSocket;
		require Padre::Plugin::Swarm::Transport::Local::Multicast;
		
		my $config = $self->config_read;
		$self->config( $config );
		
		
		$self->geometry( Padre::Swarm::Geometry->new );
		
		my $editor = Padre::Plugin::Swarm::Wx::Editor->new();
		$self->editor($editor);
		$editor->enable;

		my $chat = Padre::Plugin::Swarm::Wx::Chat->new( $self->main );
		$self->chat( $chat );
		$chat->enable;


		my $directory = Padre::Plugin::Swarm::Wx::Resources->new(
			$self->main
		);
		$self->resources( $directory );
		$directory->enable;

		$self->connect();
		1;
	}

	sub plugin_disable {
		my $self = shift;
		$self->chat->disable;
		$self->chat(undef);
		
		$self->resources->disable;
		$self->resources(undef);
	
		$self->editor->disable;
		$self->editor(undef);
		
		$self->wx->Destroy;
		$self->wx(undef);
		$self->disconnect;
		
	
		undef $instance;
	
		
	}
}

# TODO Re-anable this when padre can survive plugin_preferences death
sub NOT_plugin_preferences {
	my $self = shift;
	my $wx = shift;
	if  ( $self->instance ) {
		die "Please disable plugin before editing preferences\n";
		
	}
	eval { 
		my $dialog = Padre::Plugin::Swarm::Wx::Preferences->new($wx);
		$dialog->ShowModal;
		$dialog->Destroy;
	};
	
	TRACE( "Preferences error $@" ) if DEBUG && $@;
	
	return;
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

=head1 FEATURES

=over

=item Global server transport

=item Local network multicast transport.

=item User chat - converse with other padre editors

=item Resources - browse and open files from other users' editor

=item Remote execution! Run arbitary code in other users' editor

=back

=head1 SEE ALSO

L<Padre::Swarm::Manual>

=head1 BUGS

Many. Identity management and interaction with L<Padre::Swarm::Geometry> is
rather poor.

Crashes when 'Reload All Plugins' is called from the padre plugin manager


=head1 COPYRIGHT

Copyright 2009-2010 The Padre development team as listed in Padre.pm

=head1 LICENSE

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
