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

# TODO Register events , catch swarm messages and apply them to open documents
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
	eval {
	Wx::Event::EVT_COMMAND(
	    $self->plugin->wx,
	    -1,
	    $self->plugin->message_event,
	    sub { $self->on_swarm_message(@_) },
	);
	};
	
	# TODO - when enabled - announce the open editor tabs!
	# TODO - when disco - announce the open editor tabs
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
	return unless $document->filename;
	
	eval {
            $self->plugin->send( {
                type => 'destroy' , 
                service => 'editor',
                resource => $document->filename}
            );

        delete $self->editors->{refaddr $editor};
        delete $self->resources->{$document->filename};
	};
        TRACE( "Failed to promote editor close! $@" ) if DEBUG && $@;
}

sub on_swarm_message {
	my ($self,$main,$event) = @_;
	my $data = $event->GetData;
	my $message = Storable::thaw( $data );
	# TODO - perform the geometry manipulation here and only update when 
	# necessary

	
	my $handler = 'accept_' . $message->{type};
	TRACE( $handler ) if DEBUG;
	if ($self->can($handler)) {
		eval { $self->$handler($message) };
		TRACE( "$handler failed - $@" ) if DEBUG && $@;
	}
	
	# don't hog the troff
	$event->Skip(1);
	
}
# message handlers

sub accept_openme {
    my ($self,$message) = @_;
    $self->plugin->main->new_document_from_string( $message->body );
}

sub accept_gimme {
	my ($self,$message) = @_;
	
	my $r = $message->{resource};
	$r =~ s/^://;
	TRACE( $message->{from} . ' requests resource ' . $r ) if DEBUG;

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
	TRACE( $message->{from} . " disco" ) if DEBUG;
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
