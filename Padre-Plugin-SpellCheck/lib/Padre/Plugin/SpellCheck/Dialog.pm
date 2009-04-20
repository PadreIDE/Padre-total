#
# This file is part of Padre::Plugin::SpellCheck.
# Copyright (c) 2009 Jerome Quelin, all rights reserved.
#
# This program is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself.
#
#

package Padre::Plugin::SpellCheck::Dialog;

use warnings;
use strict;

use Class::XSAccessor accessors => {
    _engine => '_engine',       # pps:engine object
    _error  => '_errorpos',     # first error spotted [ $word, $pos, $suggestions ]
    _sizer  => '_sizer',        # window sizer
    _text   => '_text',         # text being spellchecked
};

use Padre::Current;
use Padre::Wx ();

use base 'Wx::Frame';


# -- constructor

sub new {
    my ($class, %params) = @_;

    # create object
    my $self = $class->SUPER::new(
        Padre::Current->main,
        -1,
        Wx::gettext('Spelling'),
        Wx::wxDefaultPosition,
        Wx::wxDefaultSize,
        Wx::wxDEFAULT_FRAME_STYLE|Wx::wxTAB_TRAVERSAL,
    );
    $self->SetIcon( Wx::GetWxPerlIcon() );
    $self->_error ( $params{error}  );
    $self->_engine( $params{engine} );
    $self->_text  ( $params{text}   );

    # create dialog
    $self->_create;

    return $self;
}

# -- public methods



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
    $self->SetSizer($sizer);
    $self->_sizer($sizer);

    $self->_create_labels;
    $self->_create_list;
    $self->_create_buttons;
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

    my $ba  = Wx::Button->new( $self, -1, Wx::gettext('Add to dictionary') );
    my $br  = Wx::Button->new( $self, -1, Wx::gettext('Replace') );
    my $bra = Wx::Button->new( $self, -1, Wx::gettext('Replace all') );
    my $bi  = Wx::Button->new( $self, -1, Wx::gettext('Ignore') );
    my $bia = Wx::Button->new( $self, -1, Wx::gettext('Ignore all') );
    my $bc  = Wx::Button->new( $self, -1, Wx::gettext('Close') );

    my $sizer = $self->_sizer;
    $sizer->Add( $ba,  Wx::GBPosition->new(0,2), Wx::GBSpan->new(1,1), Wx::wxEXPAND );
    $sizer->Add( $br,  Wx::GBPosition->new(2,2), Wx::GBSpan->new(1,1), Wx::wxEXPAND );
    $sizer->Add( $bra, Wx::GBPosition->new(3,2), Wx::GBSpan->new(1,1), Wx::wxEXPAND );
    $sizer->Add( $bi,  Wx::GBPosition->new(4,2), Wx::GBSpan->new(1,1), Wx::wxEXPAND );
    $sizer->Add( $bia, Wx::GBPosition->new(5,2), Wx::GBSpan->new(1,1), Wx::wxEXPAND );
    $sizer->Add( $bc,  Wx::GBPosition->new(7,2), Wx::GBSpan->new(1,1), Wx::wxEXPAND );

    $_->Disable for ($ba, $br, $bra, $bi, $bia, $bc);
}

#
# $dialog->_create_labels;
#
# create the top labels.
#
# no params. no return values.
#
sub _create_labels {
    my ($self) = @_;
    my $sizer  = $self->_sizer;

    # create the labels...
    my $lab1 = Wx::StaticText->new( $self, -1, Wx::gettext('Not in dictionary:') );
    my $lab2 = Wx::StaticText->new( $self, -1, Wx::gettext('Suggestions') );
    my $labword = Wx::StaticText->new( $self, -1, $self->_error->[0] );

    # ... and place them
    $sizer->Add( $lab1,    Wx::GBPosition->new(0,0) );
    $sizer->Add( $lab2,    Wx::GBPosition->new(1,0), Wx::GBSpan->new(1,3), Wx::wxEXPAND );
    $sizer->Add( $labword, Wx::GBPosition->new(0,1), Wx::GBSpan->new(1,1), Wx::wxEXPAND );
}

#
# $dialog->_create_list;
#
# create the suggestions list.
#
# no params. no return values.
#
sub _create_list {
    my ($self) = @_;

    my $list = Wx::ListView->new(
        $self,
        -1,
        Wx::wxDefaultPosition,
        Wx::wxDefaultSize,
        Wx::wxLC_SINGLE_SEL,
    );
    $self->_sizer->Add( $list,
        Wx::GBPosition->new(2,0),
        Wx::GBSpan->new(5,2),
        Wx::wxEXPAND
    );

}


1;

__END__


=head1 NAME

Padre::Plugin::SpellCheck::Dialog - dialog for padre spell check



=head1 DESCRIPTION

This module implements the dialog window that will be used to interact
with the user when mistakes have been spotted.



=head1 PUBLIC METHODS

=head2 Constructor

=over 4

=item my $dialog = PPS::Dialog->new( $text, $word, $pos, $suggestions );

Create and return a new dialog window. The following params are needed:

=over 4

=item text => $text

The text being spell checked.

=item error => [ $word, $pos, $suggestions ]

The first spotted error, on C<$word> (at position C<$pos>), with some
associated C<$suggestions> (a list reference).

=item engine => $engine

The $engine being used (a C<Padre::Plugin::SpellCheck::Engine> object).

=back

=back



=head2 Instance methods

=over 4

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
