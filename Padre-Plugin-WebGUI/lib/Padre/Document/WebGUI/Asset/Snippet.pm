package Padre::Document::WebGUI::Asset::Snippet;

# ABSTRACT: Padre::Document::WebGUI::Asset::Snippet subclass representing a WebGUI Snippet

use strict;
use warnings;
use Padre::Logger;
use Padre::Document::WebGUI::Asset;

our @ISA = 'Padre::Document::WebGUI::Asset';

=method lexer

Snippets know what their mime type is

=cut

sub lexer {
    my $self     = shift;
    my $mimetype = $self->asset->{mimetype};
    TRACE("Snippet mimetype: $mimetype") if DEBUG;
    Padre::MimeTypes->get_lexer( $mimetype || 'text/html' );
}

=method TRACE

=cut

1;
