package Padre::Document::WebGUI::Asset::Snippet;

use 5.008;
use strict;
use warnings;
use Padre::Debug;
use Padre::Document::WebGUI::Asset;

our @ISA = 'Padre::Document::WebGUI::Asset';

# Snippets know what their mime type is
sub lexer {
    my $self     = shift;
    my $mimetype = $self->asset->{mimetype};
    TRACE("Snippet mimetype: $mimetype") if DEBUG;
    Padre::MimeTypes->get_lexer( $mimetype || 'text/html' );
}

1;
