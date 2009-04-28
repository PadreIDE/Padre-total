#
# This file is part of Padre::Plugin::SpellCheck.
# Copyright (c) 2009 Jerome Quelin, all rights reserved.
#
# This program is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself.
#
#

package Padre::Plugin::SpellCheck::Preferences;

use warnings;
use strict;

use Class::XSAccessor accessors => {
    _sizer       => '_sizer',        # window sizer
};

use Padre::Current;
use Padre::Wx ();

use base 'Wx::Dialog';


# -- constructor

sub new {
    my ($class) = @_;

    # create object
    my $self = $class->SUPER::new(
        Padre::Current->main,
        -1,
        Wx::gettext('Spelling preferences'),
        Wx::wxDefaultPosition,
        Wx::wxDefaultSize,
        Wx::wxDEFAULT_FRAME_STYLE|Wx::wxTAB_TRAVERSAL,
    );
    $self->SetIcon( Wx::GetWxPerlIcon() );

    # create dialog
    $self->_create;

    return $self;
}


# -- event handler

sub _on_butok_clicked {
    my ($self) = @_;
    $self->Destroy;
}


# -- private methods

#
# $self->_create;
#
# create the dialog itself.
#
# no params, no return values.
#
sub _create {
    my ($self) = @_;

    # create sizer that will host all controls
    my $sizer = Wx::BoxSizer->new( Wx::wxVERTICAL );
    $self->_sizer($sizer);

    # create the controls
    $self->_create_dictionaries;
    $self->_create_buttons;

    # wrap everything in a vbox to add some padding
    $self->SetSizerAndFit($sizer);
    $sizer->SetSizeHints($self);
}

#
# $dialog->_create_buttons;
#
# create the buttons pane.
#
# no params. no return values.
#
sub _create_buttons {
    my ($self) = @_;
    my $sizer  = $self->_sizer;

    my $butsizer = $self->CreateStdDialogButtonSizer(Wx::wxOK|Wx::wxCANCEL);
    $sizer->Add($butsizer, 0, Wx::wxEXPAND|Wx::wxCENTER, 1 );
    Wx::Event::EVT_BUTTON( $self, Wx::wxID_OK,     \&_on_butok_clicked );
}

#
# $dialog->_create_dictionaries;
#
# create the pane to choose the spelling dictionary.
#
# no params. no return values.
#
sub _create_dictionaries {
    my ($self) = @_;

    my $engine  = Padre::Plugin::SpellCheck::Engine->new;
    my @choices = $engine->dictionaries;
    my $default = $choices[0];

    # create the controls
    my $label = Wx::StaticText->new( $self, -1, Wx::gettext('Dictionary:') );
    my $combo = Wx::ComboBox->new( $self, -1,
        $default,
        Wx::wxDefaultPosition,
        Wx::wxDefaultSize,
        \@choices,
        Wx::wxCB_READONLY|Wx::wxCB_SORT,
    );

    # pack the controls in a box
    my $box = Wx::BoxSizer->new(Wx::wxHORIZONTAL);
    $box->Add( $label, 0, Wx::wxEXPAND|Wx::wxCENTER, 5 );
    $box->Add( $combo, 1, Wx::wxEXPAND|Wx::wxCENTER, 5 );
    $self->_sizer->Add( $box, 0, Wx::wxEXPAND|Wx::wxCENTER, 5 );
}


1;

__END__


=head1 NAME

Padre::Plugin::SpellCheck::Preferences - preferences dialog for padre spell check



=head1 DESCRIPTION

This module implements the dialog window that will be used to set the
spell check preferences.



=head1 PUBLIC METHODS

=head2 Constructor

=over 4

=item my $dialog = PPS::Preferences->new( %params );

Create and return a new dialog window.


=back




=head1 SEE ALSO

For all related information (bug reporting, source code repository,
etc.), refer to L<Padre::Plugin::SpellCheck>.



=head1 AUTHOR

Jerome Quelin, C<< <jquelin@cpan.org> >>



=head1 COPYRIGHT & LICENSE

Copyright (c) 2009 Jerome Quelin, all rights reserved.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
