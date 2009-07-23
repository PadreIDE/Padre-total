package Padre::Wx::Role::MainChild;

=pod

=head1 NAME

Padre::Wx::Role::MainChild - Convenience methods for children of the main window

=head1 DESCRIPTION

This psuedo-role implements the fairly common method pattern for Wx elements that
are children of L<Padre::Wx::Main>.

=head1 METHODS

=cut

use strict;
use warnings;
use Padre::Current ();

our $VERSION = '0.41';

# The three most common things we need are implemented directly

=pod

=head2 main

    my $main = $object->main;

Get the L<Padre::Wx::Main> main window that this object is a child of.

=cut

sub main {
	$_[0]->GetParent;
}

=pod

=head2 ide

    my $ide = $object->ide;

Get the L<Padre> IDE instance that this object is a child of.

=cut

sub ide {
	$_[0]->GetParent->ide;
}

=pod

=head2 config

    my $config = $object->config;

Get the L<Padre::Config> for the current user. Provided mainly as a
convenience because it is needed so often.

=cut

sub config {
	$_[0]->GetParent->config;
}

=pod

=head2 current

    my $current = $object->current;

Get a new C<Padre::Current> context object.

=cut

sub current {
	Padre::Current->new( main => $_[0]->GetParent );
}

1;

=pod

=back

=head1 COPYRIGHT & LICENSE

Copyright 2008-2009 The Padre development team as listed in Padre.pm.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut

# Copyright 2008-2009 The Padre development team as listed in Padre.pm.
# LICENSE
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl 5 itself.
