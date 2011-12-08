package Padre::Wx::Menu::Debug;

# Fully encapsulated Debug menu

use 5.008;
use strict;
use warnings;
use Padre::Wx       ();
use Padre::Wx::Menu ();
use Padre::Current  ();

our $VERSION = '0.93';
our @ISA     = 'Padre::Wx::Menu';


#####################################################################
# Padre::Wx::Menu Methods

sub new {
	my $class = shift;
	my $main  = shift;

	# Create the empty menu as normal
	my $self = $class->SUPER::new(@_);

	# Add additional properties
	$self->{main} = $main;

	$self->{panel_breakpoints} = $self->add_menu_action(
		'debug.panel_breakpoints',
	);

	$self->{panel_debug_output} = $self->add_menu_action(
		'debug.panel_debug_output',
	);

	$self->{panel_debugger} = $self->add_menu_action(
		'debug.panel_debugger',
	);

	$self->AppendSeparator;

	$self->{launch} = $self->add_menu_action(
		'debug.launch',
	);

	$self->{set_breakpoint} = $self->add_menu_action(
		'debug.set_breakpoint',
	);

	$self->{quit} = $self->add_menu_action(
		'debug.quit',
	);

	$self->AppendSeparator;

	$self->{visit_debug_wiki} = $self->add_menu_action(
		'debug.visit_debug_wiki',
	);

	return $self;
}

sub title {
	Wx::gettext('&Debug');
}

sub refresh {
	my $self     = shift;
	my $main     = shift;
	my $current  = Padre::Current::_CURRENT(@_);
	my $config   = $current->config;
	my $document = Padre::Current::_CURRENT(@_)->document;
	my $hasdoc   = $document ? 1 : 0;

	$self->{panel_breakpoints}->Check( $config->main_panel_breakpoints );
	$self->{panel_debug_output}->Check( $config->main_panel_debug_output );
	$self->{panel_debugger}->Check( $config->main_panel_debugger );

	$self->{launch}->Enable(1);
	$self->{set_breakpoint}->Enable(1);
	$self->{quit}->Enable(1);

	$self->{visit_debug_wiki}->Enable(1);

	return 1;
}

1;

# Copyright 2008-2011 The Padre development team as listed in Padre.pm.
# LICENSE
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl 5 itself.
