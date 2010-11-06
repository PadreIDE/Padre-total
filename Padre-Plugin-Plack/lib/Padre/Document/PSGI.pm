package Padre::Document::PSGI;

# ABSTRACT: Handlers PSGI files in Padre

use strict;
use warnings;

use Padre::Logger;
use Padre::Document::Perl;
use Padre::MimeTypes;

our @ISA = 'Padre::Document::Perl';

use Class::XSAccessor accessors => [qw(icon_path icon_set panel plugin process)];

=method icon_path

=method icon_set

=method panel

=method panel

=method plugin

=method process

=method on_load

=cut

sub on_load {
    my $self = shift;

    TRACE('->on_load') if DEBUG;

    require Scalar::Util;
    Scalar::Util::weaken( $self->{plugin} );
}

=method set_tab_icon

Care needs to be taken that this is called *after* the new tab has been
created, otherwise you'll end up setting the icon on the wrong tab

=cut

sub set_tab_icon {
    my $self = shift;
    return if $self->icon_set;

    TRACE( ' setting icon to ' . $self->icon_path ) if DEBUG;

    my $main = Padre->ide->wx->main;
    my $id   = $main->find_id_of_editor( $self->editor );
    my $icon = Wx::Bitmap->new( $self->icon_path, Wx::wxBITMAP_TYPE_PNG );
    $main->notebook->SetPageBitmap( $id, $icon );

    $self->icon_set(1);
}

=method restore_cursor_position

=cut

sub restore_cursor_position {
    my $self = shift;

    # editor_enable gets called before the tab has been created when opening a new psgi file,
    # so we set the icon inside this method which is conveniently triggered after the tab
    # has been created in Padre::Wx::Main::setup_editor
    $self->set_tab_icon;

    return $self->SUPER::restore_cursor_position(@_);
}

=method store_cursor_position

(ab)use L<remove_tempfile> to hook in our Document onClose handler

=cut

sub store_cursor_position {
    my $self = shift;
    $self->plugin->on_doc_close($self) if ( caller(1) )[3] eq 'Padre::Wx::Main::close';
    return $self->SUPER::store_cursor_position(@_);
}

=method TRACE

=cut

1;
