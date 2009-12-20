package Padre::Document::WebGUI::Asset;

use 5.008;
use strict;
use warnings;

use Carp;
use Padre::Logger;
use Padre::Document ();

our @ISA = 'Padre::Document';

use Class::XSAccessor getters => {
    asset => 'asset',
    url   => 'url',
};

# File-faking
sub basename     { $_[0]->filename }
sub dirname      { $_[0]->basename }
sub time_on_file { $_[0]->asset->{revisionDate} }
sub load_file    { $_[0]->load_asset }
sub is_new       { 0 }

# Override this to change the highlighter/lexer
sub lexer { Padre::MimeTypes->get_lexer('text/html') }

sub load_asset {
    my ( $self, $assetId, $url ) = @_;

    TRACE( "Loading asset $assetId from $url with mimetype " . $self->get_mimetype ) if DEBUG;

    # TODO: Investigate whether we should actually subclass Padre::File rather than faking it
#    $self->{file} = {};

    $self->{url} = $url;

    # Create a user agent object
    use LWP::UserAgent;
    my $ua  = LWP::UserAgent->new;
    my $get = "$url?op=padre&func=edit&assetId=$assetId";
    TRACE("GET: $get") if DEBUG;
    my $response = $ua->get($get);
    unless ( $response->header('Padre-Plugin-WebGUI') ) {
        my $error = "The server does not appear to have the Padre::Plugin::WebGUI content handler installed";
        $self->set_errstr($error);
        $self->editor->main->error($error);
        return;
    }
    if ( !$response->is_success ) {
        my $error = "The server said:\n" . $response->status_line;
        $self->set_errstr($error);
        $self->editor->main->error($error);
        return;
    }

    return $self->process_response( $response->content );
}

# Override Padre::Document::save_file
sub save_file {
    my $self = shift;

    my $asset = $self->asset;
    return unless $asset;
    my $url = $self->url;

    # Two saves in the same second will cause asset->addRevision to explode
    return 1 if $self->last_sync && $self->last_sync == time;

    TRACE("Saving asset $asset->{assetId}") if DEBUG;

    # Put editor text back into asset hash
    $self->set_asset_content;

    # Create a user agent object
    use LWP::UserAgent;
    my $ua       = LWP::UserAgent->new;
    my $response = $ua->post(
        $url,
        {   op      => 'padre',
            func    => 'save',
            assetId => $asset->{assetId},
            props   => to_json($asset),
        }
    );
    unless ( $response->header('Padre-Plugin-WebGUI') ) {
        my $error = "The server does not appear to have the Padre::Plugin::WebGUI content handler installed";
        $self->set_errstr($error);
        $self->editor->main->error($error);
        return;
    }
    if ( !$response->is_success ) {
        $self->set_errstr( "The server said:\n" . $response->status_line );
        return;
    }

    return $self->process_response( $response->content );
}

sub process_response {
    my $self    = shift;
    my $content = shift;

    # TRACE($content) if DEBUG;

    use JSON;
    my $asset = eval { from_json($content) };
    if ($@) {
        TRACE($@) if DEBUG;
        my $error = "The server sent an invalid response, please try again (and check the logs)";
        $self->set_errstr($error);
        $self->editor->main->error($error);
        return;
    }

    $self->{asset}      = $asset;
    $self->{_timestamp} = $self->time_on_file;

    # Set a fake filename, so that we the file isn't considered 'new'
    #$self->{filename} = "[$asset->{name}] $asset->{menuTitle}"; # asset name not needed now that icon shown
    $self->{filename} = $asset->{menuTitle};

    $self->render;

    return 1;
}

# You can override this to edit something other than the generic 'content' field
sub get_asset_content {
    my $self = shift;
    return $self->asset->{content};
}

# This is paired with L<get_asset_content> - it gets called to store the editor text
# back into the appropriate asset field prior to sending hash to server
sub set_asset_content {
    my $self = shift;
    $self->asset->{content} = $self->text_get;
}

# You can override this to do something entirely different with the asset
sub render {
    my $self  = shift;
    my $asset = $self->asset;

    # Set text (a la Padre::Document::load_file)
    my $text = $self->get_asset_content || q{};

    require Padre::Locale;
    $self->{encoding} = Padre::Locale::encoding_from_string($text);
    $text = Encode::decode( $self->{encoding}, $text );

    $self->text_set($text);
    $self->{original_content} = $self->text_get;
    $self->colourize;
}

1;
