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

# -- constructor

sub new {
    my ($class) = @_;

    my $self = bless {}, $class;

    return $self;
}

1;

__END__

=head1 NAME

Padre::Plugin::SpellCheck::Engine - spell engine for plugin



=head1 DESCRIPTION

This plugins allows one to checking her text spelling within Padre. It
is using C<Text::Aspell> underneath, so check this module's pod for more
information.

Of course, you need to have the aspell binary and dictionnary installed.



=head1 PUBLIC METHODS

=head2 Constructor

=over 4

=item my $engine = PPS::Engine->new;

Create a new engine to be used later on.


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
