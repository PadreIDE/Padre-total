#
# This file is part of Padre::Plugin::SpellCheck.
# Copyright (c) 2009 Jerome Quelin, all rights reserved.
#
# This program is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself.
#
#

package Padre::Plugin::SpellCheck::Engine;

use warnings;
use strict;

use Class::XSAccessor accessors => {
    _ignore  => '_ignore',
    _speller => '_speller',
};
use Text::Aspell;


# -- constructor

sub new {
    my ($class) = @_;

    my $self = bless {
        _ignore => {},
    }, $class;

    # create speller object
    my $speller = Text::Aspell->new;
    # TODO: configurable later
    $speller->set_option('sug-mode', 'fast');
    $speller->set_option('lang','en_US');
    $self->_speller( $speller );

    return $self;
}


# -- public methods

sub check {
    my ($self, $text) = @_;
    my $speller = $self->_speller;
    my $ignore  = $self->_ignore;

    # iterate over word boundaries
    while ( $text =~ /(.+?)(\b|\z)/g ) {
        my $word = $1;

        # skip...
        next unless defined $word;              # empty strings
        next unless $word =~ /^\p{Letter}+$/i;  # non-spellable words
        next if exists $ignore->{$word};        # ignored words

        # check spelling
        next if $speller->check( $word );

        # oops! spell mistake!
        my $pos = pos($text) - length($word);
        return $word, $pos;
    }

    # $text does not contain any error
    return;
}

sub ignore {
    my ($self, $word) = @_;
    $self->_ignore->{$word} = 1;
}

sub suggestions {
    my ($self, $word) = @_;
    return $self->_speller->suggest( $word );
}

1;

__END__

=head1 NAME

Padre::Plugin::SpellCheck::Engine - spell engine for plugin



=head1 DESCRIPTION



=head1 PUBLIC METHODS

=head2 Constructor

=over 4

=item my $engine = PPS::Engine->new;

Create a new engine to be used later on.


=back



=head2 Instance methods

=over 4

=item * my ($word, $pos) = $engine->check( $text );

Spell check C<$text> (according to current speller), and return the
first error encountered (undef if no spelling mistake). An error is
reported as the faulty C<$word>, as well as the C<$pos> of the word in
the text (position of the start of the faulty word).


=item * $engine->ignore( $word );

Tell engine to ignore C<$word> for rest of the spell check.


=item * my @suggestions = $engine->suggestions( $word );

Return suggestions for C<$word>.



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
