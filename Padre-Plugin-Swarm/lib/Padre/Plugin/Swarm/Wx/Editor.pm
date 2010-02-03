package Padre::Plugin::Swarm::Wx::Editor;

use strict;
use warnings;
use Scalar::Util qw( refaddr );
use Padre::Logger;

use Class::XSAccessor
    accessors => {
        editors => 'editors',
        resources=> 'resources',
        
    };

# TODO 
# Register events , catch swarm messages and apply them to open documents
# 
sub new {
	my $class = shift;
	my %args  = @_;
	TRACE( "Instanced editor supervisor" ) if DEBUG;
	$args{editors} = {};
	$args{resources} = {};
	return bless \%args, $class ;
}

sub enable {
	my $self = shift;
#	eval {
#	Wx::Event::EVT_COMMAND(
#	    $self->plugin->main,
#	    -1,
#	    $self->plugin->message_event,
#	    sub { $self->on_swarm_message(@_) },
#	);
#	};
#	
	TRACE( "Failed to enable editor - $@" ) if DEBUG && $@;
}

sub disable {}

sub plugin { Padre::Plugin::Swarm->instance }

sub editor_enable {
	my ($self,$editor,$document) = @_;
	return unless $document->filename;
	
        eval  {
	    $self->plugin->send(
		{ 
			type => 'promote', service => 'editor',
			resource => $document->filename
		}
	    );
	
	};
	
	$self->editors->{ refaddr $editor } = $editor;
	$self->resources->{ $document->filename } = $document;
	
	
	TRACE( "Failed to promote editor open! $@" ) if DEBUG && $@;

}

# TODO - document->filename should be $self->canonical_resource($document); ?

sub editor_disable {
	my ($self,$editor,$document) = @_;
	
	eval {
            $self->plugin->send( {
                type => 'destroy' , 
                service => 'editor',
                resource => $document->filename}
            );
        };
        delete $self->editors->{refaddr $editor};
        delete $self->resources->{refaddr $document};
        
        TRACE( "Failed to promote editor close! $@" ) if DEBUG && $@;
}

sub on_swarm_message {
	my ($self,$main,$event) = @_;
	my $message = $event->GetData;
	TRACE( "Got message event $event from $main" ) if DEBUG;
	
	
}
# message handlers

sub accept_openme {
    my ($self,$message) = @_;
    eval {
	$self->main->new_document_from_string( $message->body );
    };
}

sub accept_gimme {
	my ($self,$message) = @_;
	
	my $r = $message->{resource};
	
	if ( exists $self->resources->{$r} ) {
		my $document = $self->resources->{$r};
		$self->plugin->send(
		    { 	type => 'openme',
			service => 'editor',
			body => $document->text_get,
		}
		);
	}
	
}

sub accept_disco {
	my ($self,$message) = @_;

	foreach my $doc ( values %{ $self->resources } ) {
	    eval  {
		$self->plugin->send(
		{ type => 'promote', service => 'editor',
		    resource => $doc->filename }
		);
	    };
	}
	
}

1;
