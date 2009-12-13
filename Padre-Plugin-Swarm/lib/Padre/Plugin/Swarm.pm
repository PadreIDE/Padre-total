package Padre::Plugin::Swarm;

use 5.008;
use strict;
use warnings;
use File::Spec             ();
use Padre::Constant        ();
use Padre::Wx              ();
use Padre::Plugin          ();
use Padre::Wx::Icon        ();

our $VERSION = '0.06';
our @ISA     = 'Padre::Plugin';

use Class::XSAccessor
	getters => {
		get_config   => 'config',
		get_services => 'services',
		get_chat     => 'chat',
		get_sidebar  =>'sidebar',
	},
	setters => {
		set_config   => 'config',
		set_services =>'services',
		set_chat     => 'chat',
		set_sidebar  => 'sidebar',
	};

# Turn this on to enable warnings
use constant DEBUG => 1;





#####################################################################
# Padre::Plugin Methods

sub padre_interfaces {
	'Padre::Plugin' => 0.51;
}

sub plugin_name {
	'Swarm!';
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
            'Run in Other Editor' => sub { $self->run_in_other_editor },
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
		$self->set_config( $config );
		
#            # Cargo WebGui
#            # workaround Padre bug
#            my %registered_documents = $self->registered_documents;
#            while ( my ( $k, $v ) = each %registered_documents ) {
#            Padre::MimeTypes->add_highlighter_to_mime_type( $k, $v );
#        }

		$self->_load_everything;
	}

	sub plugin_disable {
		my $self = shift;
		undef $instance;
		$self->_destroy_ui;
	}
}


#sub registered_documents {
#    'application/x-swarm-document' =>    
#        'Padre::Plugin::Swarm::Document',
#}
#
#
#sub editor_enable {
#	my ( $self, $editor, $doc ) = @_;
#	$self->{editor}{ refaddr $editor} = 1; 
#	return 1;
#}
#
## Does this really happen ? # cargo from Plugin::Vi
#sub editor_stop {
#	my ( $self, $editor, $doc ) = @_;
#	delete $self->{editor}{ refaddr $editor};
#
#	return 1;
#}

# oh noes!
sub run_in_other_editor {
    my $self = shift;
    my $ed = $self->current->editor;
    my $doc = $self->current->document;
    $self->get_chat->tell_service(
        Padre::Swarm::Message->new(
            type => 'runme',
            body => $ed->GetText,
            filename => $doc->filename,
        )
    );
    
}

#####################################################################
# Custom Methods

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


###
# Private

sub _load_everything {
	my $self   = shift;
	my $config = $self->get_config;

	# TODO bootstrap some config and construct
	# services/transports. for now just chat
	my $chatframe = Padre::Wx::Swarm::Chat->new($self->main);
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

# Copyright 2008-2009 The Padre development team as listed in Padre.pm.
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
