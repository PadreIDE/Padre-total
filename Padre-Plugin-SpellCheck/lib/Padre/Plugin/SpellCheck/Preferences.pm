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
    my $sizer = Wx::GridBagSizer->new( 5, 5 );
    $sizer->AddGrowableCol(1);
    $sizer->AddGrowableRow(6);
    $self->_sizer($sizer);


    # wrap everything in a vbox to add some padding
    my $vbox  = Wx::BoxSizer->new( Wx::wxVERTICAL );
    $vbox->Add( $sizer, 1, Wx::wxEXPAND|Wx::wxALL, 5 );
    $self->SetSizerAndFit($vbox);
    $vbox->SetSizeHints($self);
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
