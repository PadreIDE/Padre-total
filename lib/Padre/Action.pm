package Padre::Action;

use 5.008;
use strict;
use warnings;

use Padre::Constant ();
use Padre::Action::Refactor();
use Padre::Action::Run();

our $VERSION = '0.48';

# Generate faster accessors
use Class::XSAccessor getters => {
	id            => 'id',
	icon          => 'icon',
	name          => 'name',
	label         => 'label',
	shortcut      => 'shortcut',
	menu_event    => 'menu_event',
	toolbar_event => 'toolbar_event',
	menu_method   => 'menu_method',
};



#####################################################################
# Functions

# This sub calls all the other files which actually create the actions
sub create {
	Padre::Action::Refactor->new();
	Padre::Action::Run->new();


	# This is made for usage by the developers to create a complete
	# list of all actions used in Padre. It outputs some warnings
	# while dumping, but they're ignored for now as it should never
	# run within a productional copy.
	if ( $ENV{PADRE_EXPORT_ACTIONS} ) {
		require Data::Dumper;
		require File::Spec;
		$Data::Dumper::Purity = 1;
		open my $action_export_fh, '>', File::Spec->catfile( Padre::Constant::CONFIG_DIR, 'actions.dump' );
		print $action_export_fh Data::Dumper::Dumper( Padre->ide->actions );
		close $action_export_fh;
	}
}



#####################################################################
# Constructor

sub new {
	my $class = shift;
	my $self = bless {@_}, $class;
	$self->{id} ||= -1;

	if ( ( !defined( $self->{name} ) ) or ( $self->{name} eq '' ) ) {
		warn join( ',', caller ) . " tried to create an action without name";
		return;
	}

	if ( defined( $self->{menu_event} ) ) {

		# Menu events are handled by Padre::Action, the real events
		# should go to {event}!
		$self->add_event( $self->{menu_event} );
		$self->{menu_event} =
			eval ' return sub { ' . "Padre->ide->actions->{'" . $self->{name} . "'}->_event(\@_);" . '};';
	}

	my $name     = $self->{name};
	my $shortcut = $self->{shortcut};

	my $actions = Padre->ide->actions;
	if ( $actions->{$name} ) {
		warn "Found a duplicate action '$name'\n";
	}

	if ($shortcut) {
		foreach my $n ( keys %$actions ) {
			my $a = $actions->{$n};
			next unless $a->shortcut;
			next unless $a->shortcut eq $shortcut;
			warn "Found a duplicate shortcut '$shortcut' with " . $a->name . " for '$name'\n";
			last;
		}
	}

	$actions->{ $self->{name} } = $self;

	return $self;
}

# A label textual data without any strange menu characters
sub label_text {
	my $self  = shift;
	my $label = $self->label;
	$label =~ s/\&//g;
	return $label;
}

# Label for use with menu (with shortcut)
# In some cases ( http://padre.perlide.org/trac/ticket/485 )
# if a stock menu item also gets a short-cut it stops working
# hence we add the shortcut only if id == -1 indicating this was not a
# stock menu item
# The case of F12 is a special case as it uses a stock icon that does not have
# a shortcut in itself so we added one.
# (BTW Print does not have a shortcut either)
sub label_menu {
	my $self  = shift;
	my $label = $self->label;
	if ( $self->shortcut
		and ( ( $self->shortcut eq 'F12' ) or ( $self->id == -1 or Padre::Constant::WIN32() ) ) )
	{
		$label .= "\t" . $self->shortcut;
	}
	return $label;
}

# Add an event to an action:
sub add_event {
	my $self      = shift;
	my $new_event = shift;

	if ( ref($new_event) ne 'CODE' ) {
		warn 'Error: ' . join( ',', caller ) . ' tried to add "' . $new_event . '" which is no CODE-ref!';
		return 0;
	}

	if ( ref( $self->{event} ) eq 'ARRAY' ) {
		push @{ $self->{event} }, $new_event;
	} elsif ( !defined( $self->{event} ) ) {
		$self->{event} = $new_event;
	} else {
		$self->{event} = [ $self->{event}, $new_event ];
	}

	return 1;
}

sub _event {
	my $self = shift;
	my @args = @_;

	return 1 unless defined( $self->{event} );

	if ( ref( $self->{event} ) eq 'CODE' ) {
		&{ $self->{event} }(@args);
	} elsif ( ref( $self->{event} ) eq 'ARRAY' ) {
		for my $item ( @{ $self->{event} } ) {
			next if ref($item) ne 'CODE'; # TODO: Catch error and source (Ticket #666)
			&{$item}(@args);
		}
	} else {
		warn 'Expected array or code reference but got: ' . $self->{event};
	}

	return 1;
}

#####################################################################
# Main Methods

=pod

=head1 NAME

Padre::Action - Padre Action Object

=head1 SYNOPSIS

  my $action = Padre::Action->new( 
    name       => 'file.save', 
    label      => 'Save', 
    icon       => '...', 
    shortcut   => 'CTRL-S', 
    menu_event => sub { },
  );

=head1 DESCRIPTION

This is the base class for the Padre Action API.

To be documented...

-- Ahmad M. Zawawi

=head1 METHODS

=head2 new

A default contructor for action objects.

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
