package Padre::Plugin;

=pod

=head1 NAME

Padre::Plugin - Padre Plugin API 

=head1 SYNOPSIS

  package Padre::Plugin::Foo;
  
  use strict;
  use base 'Padre::Plugin';
  
  # Declare the Padre classes we use and Padre version the code was written to
  sub padre_interfaces {
      'Padre::Document::Perl' => 0.16,
      'Padre::Wx::MainWindow' => 0.16,
      'Padre::DB'             => 0.16,
  }

  # The plugin name to show in the Plugins menu
  # The command structure to show in the Plugins menu
  sub menu_plugins_simple {
  	  'My Plugin' => [
          About => sub { $self->show_about },
          Deep  => [
              'Do Something' => sub { $self->do_something },
          ],
      ];
  }

  
  1;

=head2 METHODS

=cut

use 5.008;
use strict;
use warnings;
use Scalar::Util ();
use Padre::Wx    ();

our $VERSION = '0.18';



######################################################################
# Default Constructor

=pod

=head2 padre_interfaces

  sub padre_interfaces {
      'Padre::Document::Perl' => 0.16,
      'Padre::Wx::MainWindow' => 0.16,
      'Padre::DB'             => 0.16,
  }

In Padre, plugins are permitted to make relatively deep calls into
Padre's internals.

To compensate for any potential problems with API compatibility, the second
generation Padre Plugin Manager will will look for each Plugin module to
define the Padre classes that the Plugin uses, and the version of Padre that
the code was originally written against.

This information will be used by the plugin manager to calculate whether or
not the Plugin is still compatible with Padre.

The list of used interfaces should be provided as a list of class/version
pairs, as shown in the example.

The padre_interfaces method will be called on the class, not on the plugin
object. By default, this method returns nothing.

In future, plugins that do NOT supply compatibility information may be
disabled unless the user has specifically allowed experimental plugins.

=cut

sub padre_interfaces {
	return ();
}

=pod

=head2 new

The new constructor takes no parameters. When a plugin is loaded,
Padre will instantiate one plugin object for each plugin, to provide
the plugin with a location to store any private or working data.

A default constructor is provided that creates an empty HASH-based
object.

=cut

sub new {
	my $class = shift;
	my $self  = bless {}, $class;
	return $self;
}

=pod

=head2 plugin_enable

The C<plugin_enable> object method will be called (at an arbitrary time of Padre's
choosing) to allow the plugin object to initialise and start up the Plugin.

This may involve loading any config files, hooking into existing documents or
editor windows, and otherwise doing anything needed to bootstrap operations.

Please note that Padre will block until this method returns, so you should
attempt to complete return as quickly as possible.

Any modules that you may use should NOT be loaded during this phase, but should
be C<require>ed when they are needed, at the last moment.

Returns true if the plugin started up ok, or false on failure.

The default implementation does nothing, and returns true.

=cut

sub plugin_enable {
	return 1;
}

=pod

=head2 plugin_disable

The C<plugin_disable> method is called by Padre for various reasons to request
the plugin do whatever tasks are necesary to shut itself down. This also
provides an opportunity to save configuration information, save caches to
disk, and so on.

Most often, this will be when Padre itself is shutting down. Other uses may
be when the user wishes to disable the plugin, when the plugin is being
reloaded, or if the plugin is about to be upgraded.

If you have any private classes other than the standard Padre::Plugin::Foo, you
should unload them as well as the plugin may be in the process of upgrading
and will want those classes freed up for use by the new version.

The recommended way of unloading your extra classes is using
L<Class::Unload>. Suppose you have C<My::Extra::Class> and want to unload it,
simply do this in C<plugin_disable>:

  require Class::Unload;
  Class::Unload->unload( "My::Extra::Class" );

Class::Unload takes care of all the tedious bits for you. Note that you
shouldn't unload any extra, external CPAN dependencies at this point
since they might be required by other plugins.

Returns true on success, or false if the unloading process failed.

=cut

sub plugin_disable {
	return 1;
}

=pod

=head2 menu_plugins_simple

  sub menu_plugins_simple {
  	  'My Plugin' => [
          About => sub { $self->show_about },
          Deep  => [
              'Do Something' => sub { $self->do_something },
          ],
      ];
  }

The C<menu_plugins_simple> method defines a simple menu structure for your
plugin.

It returns two values, the label for the menu entry to be used in the top level
Plugins menu, and a reference to an ARRAY containing an ordered set of key/value
pairs that will be turned into menus.

More complex plugins that need full control over the menu will be addressed
in the next release.

If the method return a null list, no menu entry will be created for the plugin.

=cut

sub menu_plugins_simple {
	# Plugins returning no data will not
	# be visible in the plugin menu.
	return ();
}

# Generates plugin menu
sub menu_plugins {
	my $self  = shift;
	my $name  = shift;
	my $win   = shift;
	my $items = shift;
	my $menu  = $self->_menu_plugins_submenu($win, $items);
	
}

sub _menu_plugins_submenu {
	my $self  = shift;
	my $win   = shift;
	my $items = shift;

	my $menu  = Wx::Menu->new;
	return if not $items or not ref $items or not 'ARRAY' eq ref $items;
	return if @$items % 2;

	for my $i (0 .. (@$items-2) / 2) {
		if (ref $items->[$i*2+1] eq 'ARRAY') {
			my $submenu = $self->_menu_plugins_submenu($win, $items->[$i*2 + 1]);
			$menu->Append(-1, $items->[$i*2], $submenu);
		} else {
			Wx::Event::EVT_MENU( $win, $menu->Append( -1, $items->[$i*2]), $items->[$i*2+1] );
		}
	}
	return $menu;
}





######################################################################
# Event Handlers

=pod

=head2 editor_enable

  sub editor_enable {
      my $self     = shift;
      my $editor   = shift;
      my $document = shift;
  
      # Make changes to the editor here...
  
      return 1;
  }

The C<editor_enable> method is called by Padre to provide the plugin with
an opportunity to alter the setup of the editor as it is being loaded.

This method is only triggered when new editor windows are opened. Hooking
into any existing open documents must be done within the C<plugin_enable>
method.

The method is passed two parameters, the fully set up editor object, and
the L<Padre::Document> being opened.

At the present time, this method has been provided primarily for the use
of the L<Padre::Plugin::Vi> plugin and other plugins that need
deep integration with the editor widget.

=cut

sub editor_enable {
	return 1;
}

=pod

=head2 editor_disable

  sub editor_disable {
      my $self     = shift;
      my $editor   = shift;
      my $document = shift;
  
      # Undo your changes to the editor here...
  
  return 1;

The C<editor_disable> method is the twin of the previous C<editor_enable>
method. It is called as the file in the editor is being closed, AFTER the
used has confirmed the file is to be closed.

It provides the plugin with an opportunity to clean up, remove any gui
customisations, and complete any other shutdown/close processes.

The method is passed two parameters, the fully set up editor object, and
the L<Padre::Document> being closed.

At the present time, this method has been provided primarily for the use
of the L<Padre::Plugin::Vi> plugin and other plugins that need 
deep integration with the editor widget.

=cut

sub editor_disable {
	return 1;
}

1;

=pod

=head1 AUTHOR

Adam Kennedy C<adamk@cpan.org>

=head1 SEE ALSO

L<Padre>

=head1 COPYRIGHT

Copyright 2008 Adam Kennedy.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
