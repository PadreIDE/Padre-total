package Padre::Action;

=pod

=head1 NAME

Padre::Action - Padre Action registry

=head1 DESCRIPTION

This is the base class for the Padre Action API.

To be documented...

-- Ahmad M. Zawawi

=head1 METHODS

=cut

use 5.008;
use strict;
use warnings;

our $VERSION = '0.40';

# Singleton object for Action
my $SINGLETON = undef;

#####################################################################
# Constructor

=pod

=head2 new

A default contructor for action objects.

=cut

sub new {
	my $class = shift;

	return $SINGLETON if $SINGLETON;
	my $self = bless {@_}, $class;
	$SINGLETON = $self;

	# the actions registry...
	$self->{actions} = ();

	return $self;
}

#####################################################################
# Main Methods

#
# Adds a toolbar item to a toolbar and to Padre's Action registry.
#
sub add_tool_item {
	my ( $self, $toolbar, $id, $name, $text, $listener ) = @_;

	my $tool_item = $toolbar->add_tool(
		id    => $id,
		icon  => $name,
		short => $text,
		event => $listener,
	);

	$self->_add_action( $name, $toolbar, $tool_item, $listener );

	return;
}


#
# Adds a menu item to a menu and to Padre's Action registry.
# Returns the menu item
#
sub add_menu_item {
	my ( $self, $menu, $id, $name, $text, $main, $listener ) = @_;

	my $menu_item = $menu->Append( $id, $text );
	Wx::Event::EVT_MENU( $main, $menu_item, $listener );

	$self->_add_action( $name, $menu, $menu_item, $listener );

	return $menu_item;
}

#
# Adds an action...
# (private method -- DO NOT USE)
#
sub _add_action {
	my ( $self, $name, $parent, $child, $listener ) = @_;

	push @{ $self->{actions} },
		{
		name     => $name,
		parent   => $parent,
		child    => $child,
		listener => $listener,
		};
}

#
# Returns a hash of actions...
#
# Possible usage scenarios:
#  - Call an action's listener directly.
#  - Detect registered keys.
#  - change the behavior of an action on the fly.
#
sub actions {
	my $self = shift;

	#XXX- must return a copy of actions (to prevent changing it by mistake)...
	return $self->{actions};
}

=pod

=head1 COPYRIGHT & LICENSE

Copyright 2008-2009 The Padre development team as listed in Padre.pm.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut

1;

# Copyright 2008-2009 The Padre development team as listed in Padre.pm.
# LICENSE
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl 5 itself.
