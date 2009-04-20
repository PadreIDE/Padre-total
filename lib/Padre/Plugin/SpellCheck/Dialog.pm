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

use Padre::Current;
use Padre::Wx ();

use base 'Wx::Frame';


# -- constructor

sub new {
	my ($class, $parent) = @_;

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

	# create dialog
	$self->_create;

	return $self;
}

# -- public methods



# -- private methods

sub _create {
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

=item my $dialog = PPS::Dialog->new;

Create and return a new dialog window.


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
