package Padre::Document::PSGI;

use 5.008;
use strict;
use warnings;

use Padre::Logger;
use Padre::Document::Perl;
use Padre::MimeTypes;

our @ISA = 'Padre::Document::Perl';

our $VERSION = '0.04';

use Class::XSAccessor accessors => [qw(icon_path icon_set panel plugin process)];

sub on_load {
    my $self = shift;

    TRACE('->on_load') if DEBUG;
    
    require Scalar::Util;
    Scalar::Util::weaken( $self->{plugin} );
}

# Care needs to be taken that this is called *after* the new tab has been
# created, otherwise you'll end up setting the icon on the wrong tab
sub set_tab_icon {
    my $self = shift;
    return if $self->icon_set;

    TRACE(' setting icon to ' . $self->icon_path) if DEBUG;

    my $main = Padre->ide->wx->main;
    my $id   = $main->find_id_of_editor( $self->editor );
    my $icon = Wx::Bitmap->new( $self->icon_path, Wx::wxBITMAP_TYPE_PNG );
    $main->notebook->SetPageBitmap( $id, $icon );

    $self->icon_set(1);
}

sub restore_cursor_position {
    my $self = shift;

    # editor_enable gets called before the tab has been created when opening a new psgi file,
    # so we set the icon inside this method which is conveniently triggered after the tab
    # has been created in Padre::Wx::Main::setup_editor
    $self->set_tab_icon;

    return $self->SUPER::restore_cursor_position(@_);
}

# (ab)use L<remove_tempfile> to hook in our Document onClose handler
sub store_cursor_position {
    my $self = shift;
    $self->plugin->on_doc_close($self) if (caller(1))[3] eq 'Padre::Wx::Main::close';
    return $self->SUPER::store_cursor_position(@_);
}

1;
