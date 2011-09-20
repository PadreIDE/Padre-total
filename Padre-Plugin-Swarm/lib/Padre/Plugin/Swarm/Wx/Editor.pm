package Padre::Plugin::Swarm::Wx::Editor;

use strict;
use warnings;
use Scalar::Util qw( refaddr );
use File::Basename;
use Padre::Logger;
use Padre::Constant;
use Padre::Wx::Constant;
use Class::XSAccessor
    accessors => {
        resources=> 'resources',
        universe => 'universe',
    };
    
our $SWARM_MARKER = 10;
    
=pod

=head1 NAME

Padre::Plugin::Swarm::Wx::Editor - Padre editor/network integration

=head1 DESCRIPTION

Hijack the padre editor for the purposes of co-operative editing. 

=head1 FEATURES

=over

=item *

Ghost cursors - cursor movement for common documents is relayed to
other swarm users. The left margin of the editor renders a ghost of
the remote users' cursor.

=head1 TODO

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


sub canonical_resource {
	my $self = shift;
	my $doc = shift;
	my $current = Padre::Current->new( document=>$doc );

	
	my $project_dir = $current->document->project_dir;
	my $base = File::Basename::basename( $project_dir );
	my $shortpath = $doc->filename;
	$shortpath =~ s/^$project_dir//;
	
	my $canonical = sprintf(
		'owner=%s,project=%s,path=%s',
		$self->universe, # owner
		$base, 
		$shortpath
	); 
	# TRACE( $canonical );
	return $canonical;
	
	# The old way 
	#return $self . '@' . $name;
}

sub resolve_resource {
	my $self = shift;
	my $r    = shift;
	my ($owner,$project,$path) =
		$r =~ m/^owner=(.+),project=(.+),path=(.+)$/;
	# TRACE( $r );
	# TRACE( 'Owner - ' . $owner );
	# TRACE( 'Project - ' . $project);
	# TRACE( 'Path(s) - ' . $path );
	return ( owner => $owner , project => $project , path => $path );
}



sub editor_enable {
	my ($self,$editor,$document) = @_;
        # TODO - dreadful since documents from swarm openme arrive like this
	return unless $document && $document->filename;
	
	$self->universe->send(
		{ 
			type => 'promote', service => 'editor',
			resource => $self->canonical_resource( $document )
		}
	);

	$self->resources->{ $self->canonical_resource( $document) } = $document;

}

# TODO - document->filename should be $self->canonical_resource($document); ?

sub editor_disable {
	my ($self,$editor,$document) = @_;
	return unless $document->filename;
	
	$self->universe->send(
			{
				type => 'destroy' , 
				service => 'editor',
				resource => $self->canonical_resource( $document )
			}
	);

	delete $self->resources->{ $self->canonical_resource( $document) };

}


# Swarm event handler
sub on_recv {
	my ($self,$message) = @_;
	my $handler = 'accept_' . $message->{type};
	TRACE( $handler ) if DEBUG;
	if ($self->can($handler)) {
		eval { $self->$handler($message) };
		TRACE( "$handler failed - $@" )  if $@;
	}
	
}

# message handlers

=head1 MESSAGE HANDLERS

For a given message->type

=head2 openme

Accept an openme message and open a new editor window 
with the contents of message->body

=cut

use Data::Dumper;

sub _rig_editor_events {
    my ($self,$editor,$resource) = @_;
    # catch changes to the document
    Wx::Event::EVT_STC_MODIFIED(
        $editor, -1 , sub { $self->on_editor_modified($resource,@_) }
    );
    # catch cursor movement (and a million other things) 
    Wx::Event::EVT_STC_UPDATEUI(
        $editor, -1 , sub { $self->on_editor_updateui($resource,@_) }
    );

    return ();

}

sub _rig_editor_decoration {
    my ($self,$editor) = @_;
    my $icon = $self->plugin->plugin_icon;
    # warn $icon;
     $editor->RegisterImage( 5 ,
	 $icon
     );

    $editor->MarkerDefineBitmap( $SWARM_MARKER, $icon );
    # $editor->MarkerDefine( 
        # $SWARM_MARKER,   
        # Wx::wxSTC_MARK_CHARACTER() + ord('S'),
        # Wx::SystemSettings::GetColour(Wx::SYS_COLOUR_INFOTEXT ),
        # Wx::SystemSettings::GetColour(Wx::SYS_COLOUR_DESKTOP ),
        
# #     );
    
    return ();
}

sub accept_openme {
    my ($self,$message) = @_;
    # Skip loopback 

    return if $message->from eq $self->plugin->identity->nickname;
    # Skip anything not addressed to us.
    if ( $message->to ne $self->plugin->identity->nickname ) 
    {
	TRACE( 'Bailout message to ' . $message->to ) if DEBUG;
        return;
    }
    
    my $doc = $self->plugin->main->new_document_from_string( $message->body );
    my $editor = $doc->editor;
    my $resource = $message->{resource};
    $self->resources->{$resource} = $doc;
    my $current = Padre::Current->new();
    TRACE( 'editor = ' . $current->editor ) if DEBUG;
    $self->_rig_editor_events( $editor,$resource );
    $self->_rig_editor_decoration($editor);
    
    return;
    
}

=head2 gimme

Give the requested message->resource to the sender in an 'openme'
if the resource matches one of our open documents.

=cut

sub accept_gimme {
	my ($self,$message) = @_;
	return if $message->{is_loopback};
	
	my $r = $message->{resource};
	
	my ($owner,$project,$path) = $self->resolve_resource( $r );
	
	#$r =~ s/^://; # legacy hack - remove me
	TRACE( $message->{from} . ' requests resource ' . $r ) if DEBUG;
	
	if ( exists $self->resources->{$r} ) {
		TRACE( 'Give ' . $message->from . ' resource ... ' , $r ) if DEBUG;;
		my $document = $self->resources->{$r};
		my $current = Padre::Current->new(document=>$document);
		
		$self->universe->send(
		    {
				type => 'openme',
				service => 'editor',
				body => $document->text_get,
				resource => $r,
				to   => $message->from ,
			}
		);
		TRACE( 'Register modified for resource...' , $r ) if DEBUG;
		$self->_rig_editor_events( $document->editor,$r );
		$self->_rig_editor_decoration( $document->editor );
		
		# anounce this
		$self->universe->chat->write_timestamp;
		$self->universe->chat->write_user_styled( $message->{from}, $message->{from} );
		$self->universe->chat->write_unstyled(
			' has been given a copy of ' . $document->filename . "\n"
		);
		
	} elsif ( $owner eq $self->universe ) {
			TRACE( "Gimme for myself???" );
	} else {
		# tell any future requestors to forget this resource
		TRACE( 'Tell ' . $message->from . ' to remove the resource...', $r ) if DEBUG;
		
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
		$self->universe->send(
				{ type => 'promote', service => 'editor',
				  resource => $self->canonical_resource( $doc ) }
				);

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


my %previous_cursor = ();

sub accept_cursor {
    my ($self,$message) = @_;
    return if $message->{is_loopback};


    my $resource = $message->{resource};
    my $position = $message->{body};
    unless ( exists $self->resources->{ $resource } ) {
        return;
    }
    TRACE( "Moving ghost cursor belonging to ".$message->from ) if DEBUG;
    TRACE( "position ='$position'"  ) if DEBUG;
    my $key = $resource . $message->from;
    my $doc = $self->resources->{ $resource };
    my $editor = $doc->editor;
    my $line = $editor->LineFromPosition( $position ); # I hope that is a number!
    my $previous = $previous_cursor{$key};
    TRACE( "Using line=$line for position '$position', previously '$previous'") if DEBUG;
    if ( defined $previous ) {
        $editor->MarkerDelete($previous,$SWARM_MARKER);
    }
    $editor->MarkerAdd($line,$SWARM_MARKER);
    $previous_cursor{$key} = $line;
    return;

}


=head2 delta

Half baked operational transform


=cut
sub accept_delta {
    my ($self,$message)=@_;
    # Ignore loopback
    return if $message->{is_loopback};
    TRACE( "Got delta from " . $message->{from} ) if DEBUG;
    
    if ( exists $self->resources->{ $message->{resource} } ) {
        
        $self->_apply_delta( 
            $message, 
            $self->resources->{ $message->{resource} } 
        );
        
    }
    
}




sub _apply_delta {
    my ($self,$message,$doc) = @_;
    TRACE( 'Apply delta ' , @_ ) if DEBUG;
    my $editor = $doc->editor;
    my $mask = $editor->GetModEventMask();
    $editor->SetModEventMask(0);
    
eval {
    if ($message->{op} eq 'ins') {
	$editor->InsertText( $message->{pos}, $message->{body}  );
	
    } elsif ( $message->{op} eq 'del' ) {
	$editor->SetTargetStart( $message->{pos} );
	    $editor->SetTargetEnd( $message->{pos} + length($message->body) );
	    $editor->ReplaceTarget( '' ); # compare to $message->{body} ??
    }
};

TRACE( 'Apply delta failed' , $@ ) if $@;

    $editor->SetModEventMask( $mask );
    return;

}

{ # SCOPE
# more leaks !
my %cursor_pos = ();

sub on_editor_updateui {
    my ($self,$resource,$editor,$event) = @_;
    my $pos = $editor->GetCurrentPos;
    TRACE( "Position is '$pos'" ) if DEBUG;
    if ( ! exists $cursor_pos{$resource} 
        || $cursor_pos{$resource} != $pos )
    {
        $cursor_pos{$resource} = $pos; 
        $self->universe->send(
            { type=>'cursor', resource=>$resource, body=>$pos }
        );
    } else {
        # NOOP
        return;
    } 
    
}

} # END SCOPE

sub on_editor_modified {
    my ($self,$resource,$editor,$event) = @_;
    return unless $resource;

    my $doc = $self->resources->{ $resource };
    TRACE( 'Tracking res/doc = ' , $resource , $doc , $event ) if DEBUG;
    return unless defined $doc;
    
    my $time = $doc->timestamp; # bad - resource->zerotime
    my $type = $event->GetModificationType;
    
     my %flags = (
	 insert => $type & Wx::wxSTC_MOD_INSERTTEXT,
	 delete => $type & Wx::wxSTC_MOD_DELETETEXT,
	 user   => $type & Wx::wxSTC_PERFORMED_USER,
	 undo   => $type & Wx::wxSTC_PERFORMED_UNDO,
	 redo   => $type & Wx::wxSTC_PERFORMED_REDO,
          style  => $type & Wx::wxSTC_MOD_CHANGESTYLE,
     );
    #TRACE( Dumper \%flags );
    
    return unless ( 
        $type & Wx::wxSTC_MOD_INSERTTEXT
            or
        $type & Wx::wxSTC_MOD_DELETETEXT );

    my $op = ($type & Wx::wxSTC_MOD_INSERTTEXT) ? 'ins' : 'del';
    my $text = $event->GetText;
    my $pos = $event->GetPosition;
    my $len = $event->GetLength;
    
    $self->universe->send(
        {   
            type=>'delta' , service=>'editor', op=>$op,
            body=>$text, pos=>$pos, 
            resource=>$resource,
        }
    );
}

1;
