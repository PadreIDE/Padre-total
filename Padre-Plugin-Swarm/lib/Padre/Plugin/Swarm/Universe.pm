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
	
	$self->chat(
		new Padre::Plugin::Swarm::Wx::Chat
				universe => $self,
				label => ucfirst( $origin ),
	);
	
	# $self->editor(
		# new Padre::Plugin::Swarm::Wx::Editor
	# );
	# 
	# $self->resources(
		# new Padre::Plugin::Swarm::Wx::Resources
	# );
	
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
	Padre::Plugin::Swarm->instance->send( $self->origin , $message );
}

sub on_recv {
	my $self = shift;
	TRACE( @_ );
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
		next unless $component;
		TRACE( "Notify $component with @_" ) if DEBUG;
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