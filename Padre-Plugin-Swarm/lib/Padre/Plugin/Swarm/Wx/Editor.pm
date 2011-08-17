package Padre::Plugin::Swarm::Wx::Editor;

use strict;
use warnings;
use Scalar::Util qw( refaddr );
use Padre::Logger;

use Class::XSAccessor
    accessors => {
        editors => 'editors',
        resources=> 'resources',
        universe => 'universe',
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


sub new {
	my $class = shift;
	my %args  = @_;
	TRACE( "Instanced editor supervisor" ) if DEBUG;
	$args{editors} = {};
	$args{resources} = {};
	
	my $self = bless \%args, $class ;
	my $rself = $self;
	Scalar::Util::weaken($self);
	
	$self->universe->reg_cb( 'editor_enable' , sub { shift;$self->editor_enable(@_) } );
	$self->universe->reg_cb( 'editor_disable', sub { shift;$self->editor_disable(@_) } );
	
	return $self;
}

sub enable {
	my $self = shift;
        foreach my $editor ( $self->plugin->main->editors ) {
	    eval{ $self->editor_enable( $editor, $editor->{Document} ) };
		TRACE( "Failed to enable editor - $@" ) if $@;
	}

}

sub disable {
	
}

sub plugin { Padre::Plugin::Swarm->instance }

sub editor_enable {
	my ($self,$editor,$document) = @_;
	return unless $document && $document->filename;
	
	Wx::Event::EVT_STC_MODIFIED( $editor , -1,  
            sub { $self->on_editor_modified(@_) }
        );

	$self->universe->send(
		{ 
			type => 'promote', service => 'editor',
			resource => $document->filename
		}
	);

	$self->editors->{ refaddr $editor } = $editor;
	$self->resources->{ $document->filename } = $document;
	
	
	TRACE( "Failed to promote editor open! $@" ) if DEBUG && $@;

}

# TODO - document->filename should be $self->canonical_resource($document); ?

sub editor_disable {
	my ($self,$editor,$document) = @_;
	return unless $document->filename;
	
	$self->universe->send(
			{
				type => 'destroy' , 
				service => 'editor',
				resource => $document->filename
			}
	);

	delete $self->editors->{refaddr $editor};
	delete $self->resources->{$document->filename};

}


# Swarm event handler
sub on_recv {
	my ($self,$message) = @_;
	my $handler = 'accept_' . $message->{type};
	TRACE( $handler ) if DEBUG;
	if ($self->can($handler)) {
		eval { $self->$handler($message) };
		TRACE( "$handler failed - $@" ) if DEBUG && $@;
	}
	
}


sub on_editor_modified {
    my ($self,$editor,$event) = @_;
    my $doc = $editor->main->current->document;
    return unless defined $doc;
    return unless $doc->filename;
    
    my $file = $doc->filename;
    my $time = $doc->timestamp;
    my $type = $event->GetModificationType;
    
    return unless ( 
        $type & Wx::wxSTC_MOD_INSERTTEXT
            or
        $type & Wx::wxSTC_MOD_DELETETEXT );

    my $op = ($type & Wx::wxSTC_MOD_INSERTTEXT) ? 'ins' : 'del';
    my $text = $event->GetText;
    my $pos = $event->GetPosition;
    my $len = $event->GetLength;
    
    #Debugging noise
    my $payload = "op=$type , text=$text, length=$len, position=$pos , time=$time :: $file";
    $self->transport->send(
        { type=>'chat', body=>$payload,
            op   => $type,
            t    => $text,
            time => time(),
        }
    );
    
    $self->transport->send(
        {   
            type=>'delta' , service=>'editor', op=>$op,
            body=>$text, pos=>$pos,
            resource=>$file,
        }
    );
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
    
    my $doc = $self->plugin->main->new_document_from_string( $message->body );
    TRACE( "Storing $doc with " . $message->{resource} ) if DEBUG;
    $self->{documents}{$message->{resource}} = $doc;
    
}

=head2 gimme

Give the requested message->resource to the sender in an 'openme'
if the resource matches one of our open documents.

=cut

sub accept_gimme {
	my ($self,$message) = @_;
	
	my $r = $message->{resource};
	$r =~ s/^://;
	TRACE( $message->{from} . ' requests resource ' . $r ) ;
	
	if ( exists $self->resources->{$r} ) {
		my $document = $self->resources->{$r};
		$self->universe->send(
		    {
				type => 'openme',
				service => 'editor',
				body => $document->text_get,
				resource => $document->filename,
				to   => $message->from ,
			}
		);
	} else {
		$self->universe->send(
			{ type => 'destroy', service=>'editor', resource=>$r }
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
		TRACE( "Promoting " . $doc->filename ) if DEBUG;
	    eval  {
		$self->transport->send(
				{ type => 'promote', service => 'editor',
				  resource => $doc->filename }
				);
	    };
	    
	    if ($@) {
			TRACE("Failed to send - $@" ) if DEBUG;
		}
	    
	}
	
}

=head2 runme

Disabled.
Execute a message body with string eval

=cut


sub NEVER_accept_runme {
    my ($self,$message) = @_;
    # Previously the honour system - now pure evil.
    return if $message->token eq $self->transport->token;
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

=head2 delta

Half baked operational transform


=cut
sub accept_delta {
    my ($self,$message)=@_;
    # Ignore loopback
    return if ($message->{token} eq $self->transport->token);
    
    if ( exists $self->{documents}{$message->{resource}} ) {
        
        $self->_apply_delta( 
            $message, 
            $self->{documents}{$message->{resource}} 
        );
        
    }
    
}

sub _apply_delta {
    my ($self,$message,$doc) = @_;
    my $editor;
    while ( my ( $id, $ed ) = each %{ $self->editors } ) {
        next unless $ed->{Document};
        if ( $ed->{Document} eq $doc ) { $editor = $ed; last }
        
    }
    
    if ($message->{op} eq 'ins') {
        $editor->InsertText( $message->{body} , $message->{pos} );
        
    } elsif ( $message->{op} eq 'del' ) {
        $editor->SetTargetStart( $message->{pos} );
            $editor->SetTargetEnd( $message->{pos} + $message->{len} );
            $editor->ReplaceTarget( $message->{body} );
            
        }
        
    
}

1;
