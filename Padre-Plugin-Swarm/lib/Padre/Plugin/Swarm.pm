package Padre::Plugin::Swarm;

use 5.008;
use strict;
use warnings;
use Socket;
use IO::Handle;
use File::Spec      ();
use Padre::Constant ();
use Padre::Wx       ();
use Padre::Plugin   ();
use Object::Event   ();
use Padre::Wx::Icon ();
use Padre::Logger;

our $VERSION = '0.2';
our @ISA     = ('Padre::Plugin','Padre::Role::Task','Object::Event');

sub plugin_interfaces {
	'Padre::Task' => 0.91,
	'Padre::Document' => 0.91,
}

use Class::XSAccessor {
	accessors => {
		config    => 'config',
		wx        => 'wx',
		global    => 'global',
		local     => 'local',
		service   => 'service',
	}
};

sub connect {
	my $self = shift;

	$self->global->event('enable');
	$self->local->event('enable');
	
}

sub disconnect {
	my $self = shift;


	$self->service->tell_child( 'shutdown_service' => "disabled" );
	$self->global->event('disable');
	$self->local->event('disable');
	
	# What are the chances either of these work ?
	$self->task_cancel;

}


use Params::Util '_INVOCANT';
use Carp 'confess';
use Data::Dumper;

sub on_swarm_service_message {
	my $self = shift;
	my $service = shift;
	my $message = shift;


	# Puke about this as ': shared' should only be applied to the storable data
	#  as it is moved between threads. Decoded message should NOT be :shared
	if ( threads::shared::is_shared( $message ) ) {
		TRACE('Parent RECV : shared ??? ' . Dumper $message );
		confess 'got : shared $message';
		
	}	
	unless ( _INVOCANT($message) ) {
		confess 'unblessed message ' . Dumper $message;
	}
	# do I still need this ? 
	$self->service($service);
	
	# TODO can i use 'SWARM' instead?
	my $lock = $self->main->lock('UPDATE');
	
	my $origin  = $message->origin;
	# Special case for 'connect'
	if ( $message->type eq 'connect' ) {
		if ( $origin eq 'local' ) {
			$self->local->event('connect');
		} elsif ( $origin eq 'global' ) {
			$self->global->event('connect');
		}
		return;
	}
	
	if ($origin eq 'local') {
		TRACE( 'Local message dispatch' ) if DEBUG;
		$self->local->event( 'recv' , $message );
	} elsif ( $origin eq 'global' ) {
		TRACE( 'Global message dispatch' ) if DEBUG;
		$self->global->event('recv', $message );
	} else {
		TRACE( "Unknown transport dispatch recv_$origin" );
		confess "Unknown transport dispatch recv_$origin" ;
	}	
	
	
	my $handler = 'accept_' . $message->type;
	TRACE( "send '$handler' event" ) if DEBUG;
	$self->event($handler,$message);
	
}

sub on_swarm_service_running {
	my ($self,$service) = @_;
	$self->{service} = $service;
	
	
}

sub on_swarm_service_finish {
	TRACE( "Service finished?? @_" ) if DEBUG;
	my $self = shift;
}


sub on_swarm_service_status {
	
TRACE( @_ )  if DEBUG;
my $self = shift;
$self->main->status(shift);

	
}


# Surely Padre::Role::Task would provide this?
sub task_cancel {
	my $self = shift;
	$self->task_manager->cancel( $self->{task_revision} );
}



SCOPE: {
my @outbox;
use Data::Dumper;

sub send {
	my ($self,$origin,$message) = @_;
	my $service = $self->{service};
	
	
	TRACE( 'Sending to task ~ ' . $service ) if DEBUG;
	# Be careful - we can race our task and send messages to it before it is ready
	unless ($self->{service}) {
		TRACE( "Queued service message in outbox" ) ;
		push @outbox, [$origin,$message];
		return;
	}
	
	my $handler = 'send_'.$origin;
	TRACE( "outbound handle $handler" ) if DEBUG;
	# Disable this until Task 3.? properly supports bi-directional communication
	#$self->service->tell_child( $handler => $message );
	
	# Instead use the socketpair created in plugin_enable to push data to the
	#  service thread. i think this is still prone to massive fuckup - but seems
	#  to work for me.
	eval {
			my $data = Storable::freeze( [ $handler => $message ] );
			TRACE( "Transmit storable encoded envelope size=".length($data) );
			# Cargo from AnyEvent::Handle, register_write_type =>'storable'
			$self->{parent_socket}->syswrite( pack "w/a*", $data );
	};
	if ($@) {
		TRACE( "Failed to send message down parent_socket , $@" );
	}

}

}
# END SCOPE:



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
	'Padre::Plugin' => 0.56;
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
        'About' => sub { $self->show_about },
    ];
}

# Singleton (I think)
SCOPE: {
	my $instance;

	sub new {
		$instance = shift->SUPER::new(@_);
	}

	sub instance { $instance };

	sub plugin_enable {
		my $self   = shift;
		# TODO - enforce singleton!!
		$instance  = $self;
		my $wxobj = new Wx::Panel $self->main;
		$self->wx( $wxobj );
		$wxobj->Hide;

		require Padre::Plugin::Swarm::Service;
		require Padre::Plugin::Swarm::Wx::Preferences;
		require Padre::Plugin::Swarm::Universe;
		require Padre::Swarm::Geometry;

		my $config = $self->bootstrap_config;
		$self->config( $config );

		my $u_global = 	Padre::Plugin::Swarm::Universe->new(origin=>'global');
		my $u_local  = 	Padre::Plugin::Swarm::Universe->new(origin=>'local');
		
		$self->global($u_global);
		$self->local($u_local);
	
		# copy-paste from '-f socketpair' docs. 
		my ($read,$write) = ( IO::Handle->new() , IO::Handle->new() );
		socketpair( $read, $write, AF_UNIX, SOCK_STREAM, PF_UNSPEC ) or die $!;
		
		#$read->autoflush(1);
		#$read->blocking(0);
		#$write->autoflush(1);
		#$write->blocking(0);
		binmode $write;
		$self->{parent_socket} = $write;
		$self->{child_socket}  = $read;
		
		my $fd_read = $read->fileno;
		
		$self->task_request(
				task =>'Padre::Plugin::Swarm::Service',
					on_message => 'on_swarm_service_message',
					on_finish  => 'on_swarm_service_finish',
					on_run     => 'on_swarm_service_running',
					on_status  => 'on_swarm_service_status',
					inbound_file_descriptor => $fd_read,
		);
		$self->connect();


		1;
	}

	sub plugin_disable {
		my $self = shift;

		$self->wx->Destroy;
		$self->wx(undef);
		$self->disconnect;
		
		undef $instance;


	}
}

sub plugin_preferences {
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

sub bootstrap_config {
	my $self = shift;
	my $config = $self->config_read;
	@$config{qw/
		nickname
		token
		transport
		local_multicast
		global_server
		bootstrap
	/} = (
		'Anonymous_'.$$,
		crypt ( rand().$$.time, 'swarm' ) ,
		'global',
		'239.255.255.1',
		'swarm.perlide.org',
		$VERSION
		) ;

	$self->config_write( $config );
	return $config;

}

sub editor_enable {
	my $self = shift;
	$self->event( 'editor_enable' , @_ );
}

sub editor_disable {
	my $self = shift;
	$self->event( 'editor_disable' , @_ );
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
that look shiny in a demo :) B<Addendum> Deliberate remote code execution was 
removed very early. Swarm no longer blindly runs code sent to it from the network.

Lessons learned here will be applied to more practical plugins later.

=head1 FEATURES

=over

=item Global server transport - Collaborate with other Swarmers on teh interwebs

=item Local network multicast transport - Collaborate with Swarmers on your local network

=item L<User chat|Padre::Plugin::Swarm::Wx::Chat> - converse with other padre editors

=item Resources - browse and open files from other users' editor

=back

=head1 SEE ALSO

L<Padre::Swarm::Manual> L<Padre::Plugin::Swarm::Wx::Chat>

=head1 BUGS

Many. Identity management and interaction with L<Padre::Swarm::Geometry> is
rather poor.

Crashes when 'Reload All Plugins' is called from the padre plugin manager


=head1 COPYRIGHT

Copyright 2009-2011 The Padre development team as listed in Padre.pm

=head1 LICENSE

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
