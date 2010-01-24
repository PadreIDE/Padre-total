package Padre::Plugin::Swarm::Wx::Editor;

use strict;
use warnings;

use Class::XSAccessor
    constructor => 'new',
    accessors => {
        editors => 'editors',
        
    };
    
# Register events ?
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

sub editor_disable {
	my ($self,$editor) = @_;
	# Surely needed someday..
}

1;
