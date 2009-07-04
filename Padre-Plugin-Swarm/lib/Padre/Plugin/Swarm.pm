package Padre::Plugin::Swarm;

use 5.008;
use strict;
use warnings;
use Padre::Constant ();
use Padre::Wx       ();
use Padre::Plugin   ();
use Padre::Wx::Icon ();
use Padre::Wx::Swarm::Chat ();

#use Padre::Wx::Swarm::Foo ();


use File::Spec      ();

use Class::XSAccessor
	getters => {
	    get_config => 'config',
	    get_services => 'services',
	    # 
	    get_chat => 'chat',
	    get_sidebar=>'sidebar',
	}
	,
	setters => {
	    set_config => 'config',
	    set_services=>'services',
	    set_chat => 'chat',
	    set_sidebar => 'sidebar',
	};

our $VERSION = '0.01';
our @ISA     = 'Padre::Plugin';







#####################################################################
# Padre::Plugin Methods

sub padre_interfaces {
	'Padre::Plugin' => 0.37;
}

sub plugin_name {
	'Swarm!';
}

sub plugin_icons_directory {
	return File::Spec->catdir( shift->plugin_share_directory(@_), 'icons');
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
		'About' => sub { $self->show_about },
	];
}

sub plugin_enable {
	my $self = shift;
	my $config = $self->config_read;
	$self->set_config( $config );

	$self->_load_everything;

	
}

sub plugin_disable {
	my $self = shift;
	$self->_destroy_ui;
}

#####################################################################
# Custom Methods

sub show_about {
	my $self = shift;

	# Generate the About dialog
	my $about = Wx::AboutDialogInfo->new;
	$about->SetName('Swarm Plugin');
	$about->SetDescription( <<"END_MESSAGE" );
Surrender to the Swarm!
END_MESSAGE
	$about->SetIcon( 
		Padre::Wx::Icon::cast_to_icon(
		  Padre::Wx::Icon::find( 'status/padre-plugin-swarm',
			{size => '128x128', icons=>$self->plugin_icons_directory } 
		  ) 
		)
	);
	# Show the About dialog
	Wx::AboutBox($about);

	return;
}


###
# Private

sub _load_everything {
	my $self = shift;
	my $config = $self->get_config; 
	# TODO bootstrap some config and construct
	# services/transports. for now just chat
	
	my $chatframe = Padre::Wx::Swarm::Chat->new($self->main);
	#my $sidebar = Padre::Wx::Swarm::VectorScope->new($self->main);
	
	#my $sidebar = Padre::Wx::Swarm::Foo->new($self->main);
	#$self->set_sidebar( $sidebar );
	
	$self->set_chat( $chatframe );
	$chatframe->enable;
}

sub _destroy_ui {
	my $self = shift;
	if ( my $chat = $self->get_chat ) {
		$chat->disable;
	}
	$self->set_chat(undef);

}

#sub _start_transports {
#	my $self = shift;
#	my $transports = $self->get_transports;
#	while ( my ($name,$transport) = each %$transports ) {
#		$transport->start;
#	}
#}
#
#sub _shutdown_transports {
#	my $self = shift;
#	my $transports = $self->get_transports;
#	while ( my ($name,$transport) = each %$transports ) {
#		$transport->shutdown;
#	}
#}

#sub _start_services {
#	my $self = shift;
#	my $services = $self->get_services;
#	while ( my ($name,$service) = each %$services ) {
#		$service->start;
#	}
#}

#sub _shutdown_services {
#	my $self = shift;
#	my $services = $self->get_services;
#	while ( my ($name,$service) = each %$services ) {
#		$service->shutdown;
#	}
#
#}
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

Copyright 2009 The Padre develoment team as listed in Padre.pm

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl 5 itself.

=cut

# Copyright 2008-2009 The Padre development team as listed in Padre.pm.
# LICENSE
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl 5 itself.
