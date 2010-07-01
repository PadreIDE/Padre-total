package Padre::Wx::Menu::Tools;

# Fully encapsulated Run menu

use 5.008;
use strict;
use warnings;
use Params::Util    ();
use Padre::Constant ();
use Padre::Config   ();
use Padre::Wx       ();
use Padre::Wx::Menu ();
use Padre::Current  ('_CURRENT');

our $VERSION = '0.65';
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

	# User Preferences
	$self->add_menu_action(
		$self,
		'edit.preferences',
	);

	# Key bindings
	$self->add_menu_action(
		$self,
		'tools.key_bindings',
	);

	# Regex Editor
	$self->add_menu_action(
		$self,
		'edit.regex',
	);

	$self->AppendSeparator;

	# Create the module tools submenu
	my $modules = Wx::Menu->new;
	$self->Append(
		-1,
		Wx::gettext('Module Tools'),
		$modules,
	);

	$self->add_menu_action(
		$modules,
		'plugins.install_cpan',
	);

	$self->add_menu_action(
		$modules,
		'plugins.install_local',
	);

	$self->add_menu_action(
		$modules,
		'plugins.install_remote',
	);

	$modules->AppendSeparator;

	$self->add_menu_action(
		$modules,
		'plugins.cpan_config',
	);

	$self->AppendSeparator;

	# Link to the Plugin Manager
	$self->add_menu_action(
		$self,
		'plugins.plugin_manager',
	);

	# Create the plugin tools submenu
	my $tools = Wx::Menu->new;
	$self->Append(
		-1,
		Wx::gettext('Plug-in Tools'),
		$tools,
	);

	# TO DO: should be replaced by a link to
	# http://cpan.uwinnipeg.ca/chapter/World_Wide_Web_HTML_HTTP_CGI/Padre
	# better yet, by a window that also allows the installation of all the
	# plugins that can take into account the type of installation we have
	# (ppm, stand alone, rpm, deb, CPAN, etc)
	$self->add_menu_action(
		$tools,
		'plugins.plugin_list',
	);

	$tools->AppendSeparator;

	$self->add_menu_action(
		$tools,
		'plugins.edit_my_plugin',
	);

	$self->add_menu_action(
		$tools,
		'plugins.reload_my_plugin',
	);

	$self->add_menu_action(
		$tools,
		'plugins.reset_my_plugin',
	);

	$tools->AppendSeparator;

	$self->add_menu_action(
		$tools,
		'plugins.reload_all_plugins',
	);

	$self->add_menu_action(
		$tools,
		'plugins.reload_current_plugin',
	);

	return $self;
}

sub add {
	my $self = shift;
	my $main = shift;

	# Clear out any existing entries
	my $entries = $self->{plugin_menus} || [];
	$self->remove if @$entries;

	# Add the enabled plugins that want a menu
	my $need    = 1;
	my $manager = Padre->ide->plugin_manager;
	foreach my $module ( $manager->plugin_order ) {
		my $plugin = $manager->_plugin($module);
		next unless $plugin->enabled;

		# Generate the menu for the plugin
		my @menu = $manager->get_menu( $main, $module ) or next;

		# Did the previous entry needs a separator after it
		if ($need) {
			push @$entries, $self->AppendSeparator;
			$need = 0;
		}

		push @$entries, $self->Append( -1, @menu );
		if ( $module eq 'Padre::Plugin::My' ) {
			$need = 1;
		}
	}

	$self->{plugin_menus} = $entries;

	return 1;
}

sub remove {
	my $self = shift;
	my $entries = $self->{plugin_menus} || [];

	while (@$entries) {
		$self->Destroy( pop @$entries );
	}

	$self->{plugin_menus} = $entries;

	return 1;
}

sub title {
	Wx::gettext('&Tools');
}

sub refresh {
	my $self = shift;
	my $main = _CURRENT(@_)->main;

	$self->remove;
	$self->add($main);

	return 1;
}

1;

# Copyright 2008-2010 The Padre development team as listed in Padre.pm.
# LICENSE
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl 5 itself.
