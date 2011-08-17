package Padre::Plugin::Swarm::Universe;
use strict;
use warnings;
use Padre::Logger;
use Class::XSAccessor 
	accessors => {
		resources => 'resources',
		origin => 'origin',
		chat => 'chat',
		geometry => 'geometry',
		transport => 'transport',
		editor => 'editor',
		label =>'label',
	};

use base qw( Object::Event );

use Padre::Plugin::Swarm::Wx::Chat;
use Padre::Plugin::Swarm::Wx::Editor;
use Padre::Plugin::Swarm::Wx::Resources;
use Padre::Swarm::Geometry;


sub components {
	qw( geometry chat resources editor )
}

sub new {
	my $class = shift;
	my %args = @_;
	
	my $self = $class->SUPER::new(%args);
	my $rself = $self;

	
	my $origin = $self->origin;
	my $plugin = Padre::Plugin::Swarm->instance;
	
	$self->reg_cb( "recv" , \&on_recv );
	$self->reg_cb( "connect" , \&on_connect);
	$self->reg_cb( "disconnect", \&on_disconnect );
	
	## Padre events from plugin - rethrow
	$self->plugin->reg_cb( 
		"editor_enable",
		sub {shift; $self->event('editor_enable', @_ ) }
	);
	$self->plugin->reg_cb( 
		"editor_disable",
		sub {shift; $self->event('editor_disable', @_ ) }
	);
	
	$self->chat(
		new Padre::Plugin::Swarm::Wx::Chat
				universe => $self,
				label => ucfirst( $origin ),
	);
	
	$self->geometry(
		new Padre::Swarm::Geometry
				
	);
	
	
	$self->editor(
		new Padre::Plugin::Swarm::Wx::Editor
				universe => $self,
	);
	# 
	$self->resources(
		Padre::Plugin::Swarm::Wx::Resources->new(
				universe => $self,
				label => ucfirst( $origin )
		)
	);
	
	Scalar::Util::weaken( $self );
	
	return $rself;
}

sub plugin { Padre::Plugin::Swarm->instance };

sub enable {
	my $self = shift;
	$self->event('enable');
	#foreach my $c ( $self->components ) {
	#	TRACE( $c ) if DEBUG;
	#	$self->$c->enable if $self->$c;
	#}
}

sub disable { 
	my $self = shift;
	$self->event('disable');
	
	#foreach my $c ( $self->components ) {
	#	$self->$c->disable if $self->$c;
	#}
}

use Data::Dumper;

sub send {
	my ($self,$message) = @_;
	
	TRACE( Dumper $message ) if DEBUG;
	$message->{from} = $self->plugin->identity->nickname;
	
	Padre::Plugin::Swarm->instance->send( $self->origin , $message );
}

sub on_recv {
	my $self = shift;
	TRACE( @_ ) if DEBUG;;
	$self->_notify( 'on_recv' , @_ );
}

sub on_connect {
	my ($self) = shift;
	TRACE( "Swarm transport connected" );
	$self->send(
		{ type=>'announce', service=>'swarm' }
	);
	$self->send(
		{ type=>'disco', service=>'swarm' }
	);
	
	$self->_notify( 'on_connect', @_ );
	
	return;
}


sub on_disconnect {
	my $self = shift;
	TRACE( "Swarm transport disconnected" ) if DEBUG;
	
	$self->_notify('on_connect', @_ );
	
}

sub _notify {
	my $self = shift;
	my $notify = shift;
	my $lock = Padre::Current->main->lock('UPDATE');
	foreach my $c ( $self->components ) {
		my $component = $self->$c;
		unless ( $component ) {
			TRACE( "$notify not handled by component $c" );
			next;
		}

		TRACE( "Notify $component -> $notify with @_" ) if DEBUG;
		eval {
			$component->$notify(@_) if $component->can($notify);
		};
		if ($@) {
			TRACE( "Failed to notify component '$c' , $@") if DEBUG
		}
	}
	return;
}



1;