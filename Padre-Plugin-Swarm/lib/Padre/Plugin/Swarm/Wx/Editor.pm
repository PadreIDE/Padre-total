package Padre::Plugin::Swarm::Wx::Editor;

use strict;
use warnings;

use Class::XSAccessor
    constructor => 'new',
    accessors => {
        editors => 'editors',
        
    };

# TODO 
# Register events , catch swarm messages and apply them to open documents
# 
sub enable {}

sub disable {}

sub plugin { Padre::Plugin::Swarm->instance }

sub editor_enable {
	my ($self,$editor,$document) = @_;

	$self->plugin->send(
            { type => 'promote', service => 'editor',
                resource => $document->filename }
	);

}

# TODO - document->filename should be $self->canonical_resource($document); ?

sub editor_disable {
	my ($self,$editor,$document) = @_;
	$self->plugin->send( 
	    type => 'leave' , 
	    service => 'editor',
	    resource => $document->filename
	);
	# Surely needed someday..
}

1;
