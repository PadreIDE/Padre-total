package Padre::Plugin::Swarm;

use 5.008;
use strict;
use warnings;
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

	# For now - use global,
	#  could be Padre::Plugin::Swarm::Transport::Local::Multicast
	#   based on preferences
	
	$self->global->event('enable');
	$self->local->event('enable');
	
}

sub disconnect {
	my $self = shift;

	$self->global->event('disable');
	$self->local->event('disable');
	
	# What are the chances either of these work ?
	$self->task_reset;

}


sub on_swarm_service_message {
	my $self = shift;
	my $service = shift;
	my $message = shift;


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
		$self->event( "recv_$origin" , $message );
	}	
	
	
	my $handler = 'accept_' . $message->type;
	TRACE( "send '$handler' event" ) if DEBUG;
	$self->event($handler,$message);
	
}

SCOPE: {
my @outbox;

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
	TRACE( "outbound handle $handler" );
	$self->service->message( $handler => $message );
	
	# Ugly - provide 'global' loopback here.
	my $loop = bless $message, 'Padre::Swarm::Message';
	$loop->{origin} = 'global';
	$self->on_swarm_service_message( $self->service ,  $loop );
	
	
	
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
		
		my $service = $self->task_request(
				task =>'Padre::Plugin::Swarm::Service',
					owner => $self,
					on_message => 'on_swarm_service_message'
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
that look shiny in a demo :)

Lessons learned here will be applied to more practical plugins later.

=head1 FEATURES

=over

=item Global server transport

=item Local network multicast transport.

=item L<User chat|Padre::Plugin::Swarm::Wx::Chat> - converse with other padre editors

=item Resources - browse and open files from other users' editor

=item Remote execution! Run arbitary code in other users' editor

=back

=head1 SEE ALSO

L<Padre::Swarm::Manual> L<Padre::Plugin::Swarm::Wx::Chat>

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
