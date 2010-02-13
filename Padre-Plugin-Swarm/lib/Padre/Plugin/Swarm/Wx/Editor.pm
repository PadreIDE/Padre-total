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
    
=pod

=head1 NAME

Padre::Plugin::Swarm::Wx::Editor - Padre editor collaboration

=head1 DESCRIPTION

Hijack the padre editor for the purposes of collaboration. 

=head1 TODO

Shared/Ghost cursors/document

Trap editor cursor movement for common documents and ghost the
remote users' cursors in the local editor.


=head2 Operational transform - concurrent remote edits

Trap the editor CHANGE event and try to transmit quanta
of operations against a document.
Trap received quanta and apply to open documents, adjusting 
local quanta w/ OT if required.

=head2 Code/Commit Review Mode.

Find the current project, find it's VCS if possible and send
the repo details and local diff to the swarm for somebody? to 
respond to.

=cut


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
	foreach my $editor ( $self->plugin->main->editors ) {
	    $self->editor_enable( $editor, $editor->{Document} )
	}
	TRACE( "Failed to enable editor - $@" ) if DEBUG && $@;
}

sub disable {}

sub plugin { Padre::Plugin::Swarm->instance }

sub editor_enable {
	my ($self,$editor,$document) = @_;
	return unless $document && $document->filename;
	
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


# Swarm event handler
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

=head1 MESSAGE HANDLERS

For a given message->type

=head2 openme

Accept an openme message and open a new editor window 
with the contents of message->body

=cut


sub accept_openme {
    my ($self,$message) = @_;
    # Skip loopback 
    return if $message->from eq $self->plugin->identity->nickname;
    # Skip anything not addressed to us.
    if ( $message->to ne $self->plugin->identity->nickname ) 
    {
	return;
    }
    
    $self->plugin->main->new_document_from_string( $message->body );
}

=head2 gimme

Give the requested message->resource to the sender in an 'openme'
if the resource matches one of our open documents.

=cut

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

=head1 disco

Respond to discovery messages by transmitting a promote for 
each known resource

=cut


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

=head2 runme

=cut


sub NEVER_accept_runme {
    my ($self,$message) = @_;
    # Previously the honour system - now pure evil.
    return if $message->from eq $self->plugin->identity->nickname;
    # Ouch..
    my @result = (eval $message->body);
    
    my $file = ($message->{filename} || 'Unknown');
    if ( $@ ) {
	
	my $reply = "Ran document $file but failed with $@";
       
	    $self->plugin->send(
		 {type => 'openme', to=>$message->from, service=>'editor',
		 body => $reply,}
	    );
        
    }
    else {
	    my $reply = 'Ran document sucessfully - returning '
		. join('', @result );
	    $self->plugin->send(
		{
			type => 'openme',
			service => 'editor',
			to=>$message->from,
			body => $reply,
			filename => $file,
		}
	    );
        
    }
    
}



1;
