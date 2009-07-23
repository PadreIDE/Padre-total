package Padre::Wx::Menu;

# Implements additional functionality to support richer menus

use strict;
use warnings;
use Padre::Wx ();

use Class::Adapter::Builder
	ISA      => 'Wx::Menu',
	NEW      => 'Wx::Menu',
	AUTOLOAD => 'PUBLIC';

our $VERSION = '0.40';

use Class::XSAccessor getters => {
	wx => 'OBJECT',
};

# Default implementation of refresh

sub refresh {1}

# Overrides and then calls XS wx Menu::Append.
# Adds any hotkeys to global registry of bound keys

sub Append {
	my $self   = shift;
	my $string = $_[1];
	my $item   = $self->wx->Append(@_);
	my ($underlined) = ( $string =~ m/(\&\w)/ );
	my ($accel)      = ( $string =~ m/(Ctrl-.+|Alt-.+)/ );
	if ( $underlined or $accel ) {
		$self->{main}->{accel_keys} ||= {};
		if ($underlined) {
			$underlined =~ s/&(\w)/$1/;
			$self->{main}->{accel_keys}->{underlined}->{$underlined} = $item;
		}
		if ($accel) {
			my ( $mod, $mod2, $key ) = ( $accel =~ m/(Ctrl|Alt)(-Shift)?\-(.)/ );
			$mod .= $mod2 if ($mod2);
			$self->{main}->{accel_keys}->{hotkeys}->{ uc($mod) }->{ ord( uc($key) ) } = $item;
		}
	}
	return $item;
}

#
# Add a normal menu item to menu from a Padre action
#
sub add_menu_item {
	my $self = shift;
	my $menu = shift;
	return $self->_add_menu_item($menu, 0, @_);
}


#
# Add a checked menu item to menu from a Padre action
#
sub add_checked_menu_item {
	my $self = shift;
	my $menu = shift;
	return $self->_add_menu_item($menu, 1, @_);
}

#
# (Private method)
# Add a normal/checked menu item to menu from a Padre action
#
sub _add_menu_item {
	my $self = shift;
	my $menu = shift;
	my $checked = shift;
	require Padre::Action;
	my $action = Padre::Action->new(@_);
	my $shortcut = $action->shortcut;
	my $menu_item;
	if(not $checked) {
		$menu_item = $menu->Append(
			$action->id,
			$action->label . ($shortcut ? ("\t" . $shortcut) : ''),
		);
	} else {
		$menu_item = $menu->AppendCheckItem(
			$action->id,
			$action->label . ($shortcut ? ("\t" . $shortcut) : ''),
		);
	}
	Wx::Event::EVT_MENU( $self->{main}, $menu_item, $action->menu_event );
	push @{Padre::ide->actions}, $action;
	#XXX- more validation of redundant items/ids
	#XXX- warnings about keyboard conflicts...
	print "Number of actions " . scalar @{Padre::ide->actions} . "\n";
	return $menu_item;
}

1;

# Copyright 2008-2009 The Padre development team as listed in Padre.pm.
# LICENSE
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl 5 itself.
