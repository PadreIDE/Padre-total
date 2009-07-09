package Padre::PluginManager;

=pod

=head1 NAME

Padre::PluginManager - Padre plugin manager

=head1 DESCRIPTION

The PluginManager class contains logic for locating and loading Padre
plugins, as well as providing part of the interface to plugin writers.

=head1 METHODS

=cut

# API NOTES:
# This class uses english-style verb_noun method naming

use strict;
use warnings;
use Carp           ();
use File::Copy     ();
use File::Glob     ();
use File::Path     ();
use File::Spec     ();
use File::Basename ();
use Scalar::Util   ();
use Params::Util qw{ _IDENTIFIER _CLASS _INSTANCE };
use Padre::Constant          ();
use Padre::Current           ();
use Padre::Util              ();
use Padre::PluginHandle      ();
use Padre::Wx                ();
use Padre::Wx::Menu::Plugins ();

our $VERSION = '0.39';

#####################################################################
# Constructor and Accessors

=pod

=head2 new

The constructor returns a new Padre::PluginManager object, but
you should normally access it via the main Padre object:

  my $manager = Padre->ide->plugin_manager;

First argument should be a Padre object.

=cut

sub new {
	my $class = shift;
	my $parent = shift || Padre->ide;
	unless ( _INSTANCE( $parent, 'Padre' ) ) {
		Carp::croak("Creation of a Padre::PluginManager without a Padre not possible");
	}

	my $self = bless {
		parent                    => $parent,
		plugins                   => {},
		plugin_names              => [],
		plugin_dir                => Padre::Constant::PLUGIN_DIR,
		par_loaded                => 0,
		plugins_with_context_menu => {},
		@_,
	}, $class;

	# initialize empty My Plugin if needed
	$self->reset_my_plugin(0);

	return $self;
}

=pod

=head2 parent

Stores a reference back to the parent IDE object.

=head2 plugin_dir

Returns the user plugin directory (below the Padre configuration directory).
This directory was added to the C<@INC> module search path and may contain
packaged plugins as PAR files.

=head2 plugins

Returns a hash (reference) of plugin names associated with a
L<Padre::PluginHandle>.

This hash is only populated after C<load_plugins()> was called.

=head2 plugins_with_context_menu

Returns a hash (reference) with the names of all plugins as
keys which define a hook for the context menu.

See L<Padre::Plugin>.

=cut

use Class::XSAccessor getters => {
	parent                    => 'parent',
	plugin_dir                => 'plugin_dir',
	plugins                   => 'plugins',
	plugins_with_context_menu => 'plugins_with_context_menu',
};

# Get the prefered plugin order.
# The order calculation cost is higher than we might like,
# so cache the result.
sub plugin_names {
	my $self = shift;
	unless ( $self->{plugin_names} ) {

		# Schwartzian transform that sorts the plugins by their
		# full names, but always puts "My Plugin" first.
		$self->{plugin_names} = [
			map { $_->[0] }
				sort { ( $b->[0] eq 'My' ) <=> ( $a->[0] eq 'My' ) or $a->[1] cmp $b->[1] }
				map { [ $_->name, $_->plugin_name ] } values %{ $self->{plugins} }
		];
	}
	return @{ $self->{plugin_names} };
}

sub plugin_objects {
	map { $_[0]->{plugins}->{$_} } $_[0]->plugin_names;
}

#####################################################################
# Bulk Plugin Operations

#
# $pluginmgr->relocale;
#
# update padre's locale object to handle new plugin l10n.
#
sub relocale {
	my $self   = shift;
	my $locale = Padre::Current->main->{locale};

	foreach my $plugin ( $self->plugin_objects ) {

		# only process enabled plugins
		next unless $plugin->status eq 'enabled';

		# add the plugin locale dir to search path
		my $object = $plugin->{object};
		if ( $object->can('plugin_locale_directory') ) {
			my $dir = $object->plugin_locale_directory;
			if ( defined $dir and -d $dir ) {
				$locale->AddCatalogLookupPathPrefix($dir);
			}
		}

		# add the plugin catalog to the locale
		my $name = $plugin->name;
		my $code = Padre::Locale::rfc4646();
		$locale->AddCatalog("$name-$code");
	}

	return 1;
}

#
# $pluginmgr->reset_my_plugin( $overwrite );
#
# reset the my plugin if needed. if $overwrite is set, remove it first.
#
sub reset_my_plugin {
	my ( $self, $overwrite ) = @_;

	# Do not overwrite it unless stated so.
	my $dst = File::Spec->catfile(
		Padre::Constant::PLUGIN_LIB,
		'My.pm'
	);
	if ( -e $dst and not $overwrite ) {
		return;
	}

	# Find the My Plugin
	my $src = File::Spec->catfile(
		File::Basename::dirname( $INC{'Padre/Config.pm'} ),
		'Plugin', 'My.pm',
	);
	unless ( -e $src ) {
		Carp::croak("Could not find the original My plugin");
	}

	# copy the My Plugin
	unlink $dst;
	unless ( File::Copy::copy( $src, $dst ) ) {
		Carp::croak("Could not copy the My plugin ($src) to $dst: $!");
	}
	chmod( 0644, $dst );
}

# Disable (but don't unload) all plugins when Padre exits.
# Save the plugin enable/disable states for the next startup.
sub shutdown {
	my $self = shift;

	Padre::DB->begin;
	foreach my $name ( $self->plugin_names ) {
		my $plugin = $self->_plugin($name);
		if ( $plugin->enabled ) {
			Padre::DB::Plugin->update_enabled(
				$plugin->class => 1,
			);
			$self->_plugin_disable($plugin);

		} elsif ( $plugin->disabled ) {
			Padre::DB::Plugin->update_enabled(
				$plugin->class => 0,
			);
		}
	}
	Padre::DB->commit;

	return 1;
}

=pod

=head2 reload_plugins

For all registered plugins, unload them if they were loaded
and then reload them.

=cut

sub reload_plugins {
	my $self    = shift;
	my $plugins = $self->plugins;
	foreach my $name ( sort keys %$plugins ) {

		# do not use the reload_plugin method since that
		# refreshes the menu every time.
		$self->_unload_plugin($name);
		$self->_load_plugin($name);
		$self->enable_editors($name);
	}
	$self->_refresh_plugin_menu;
	return 1;
}

=pod

=head2 load_plugins

Scans for new plugins in the user plugin directory, in C<@INC>,
and in C<.par> files in the user plugin directory.

Loads any given module only once, i.e. does not refresh if the
plugin has changed while Padre was running.

=cut

sub load_plugins {
	my $self = shift;
	$self->_load_plugins_from_inc;
	$self->_load_plugins_from_par;
	$self->_refresh_plugin_menu;
	if ( my @failed = $self->failed ) {

		# Until such time as we can show an error message
		# in a smarter way, this gets annoying.
		# Every time you start the editor, we tell you what
		# we DIDN'T do...
		# Turn this back on once we can track these over time
		# and only report on plugins that USED to work but now
		# have started to fail.
		#$self->parent->wx->main->error(
		#	Wx::gettext("Failed to load the following plugin(s):\n")
		#	. join "\n", @failed
		#) unless $ENV{HARNESS_ACTIVE};
		return;
	}
	return;
}

# attempt to load all plugins that sit as .pm files in the
# .padre/plugins/Padre/Plugin/ folder
sub _load_plugins_from_inc {
	my ($self) = @_;

	# Try the plugin directory first:
	my $plugin_dir = $self->plugin_dir;
	unless ( grep { $_ eq $plugin_dir } @INC ) {
		unshift @INC, $plugin_dir;
	}

	my @dirs = grep { -d $_ } map { File::Spec->catdir( $_, 'Padre', 'Plugin' ) } @INC;

	require File::Find::Rule;
	my @files = File::Find::Rule->name('*.pm')->file->maxdepth(1)->in(@dirs);
	foreach my $file (@files) {

		# Full path filenames
		my $module = $file;
		$module =~ s/\.pm$//;
		$module =~ s{^.*Padre[/\\]Plugin\W*}{};
		$module =~ s{[/\\]}{::}g;

		# TODO maybe we should report to the user the fact
		# that we changed the name of the MY plugin and she should
		# rename the original one and remove the MY.pm from his installation
		if ( $module eq 'MY' ) {
			warn "Deprecated Padre::Plugin::MY found at $file. Please remove it\n";
			return;
		}

		# Caller must refresh plugin menu
		$self->_load_plugin($module);
	}

	return;
}

=pod

=head2 alert_new

The C<alert_new> method is called by the main window post-init and
checks for new plugins. If any are found, it presents a message to
the user.

=cut

sub alert_new {
	my $self    = shift;
	my $plugins = $self->plugins;
	my @loaded  = sort
		map  { $_->plugin_name }
		grep { $_->loaded } values %$plugins;
	if ( @loaded and not $ENV{HARNESS_ACTIVE} ) {
		my $msg = Wx::gettext(<<"END_MSG") . join( "\n", @loaded );
We found several new plugins.
In order to configure and enable them go to
Plugins -> Plugin Manager

List of new plugins:

END_MSG

		$self->parent->wx->main->message(
			$msg,
			Wx::gettext('New plugins detected')
		);
	}

	return 1;
}

=pod

=head2 failed

Returns the plugin names (without C<Padre::Plugin::> prefixed) of all plugins
that the editor attempted to load but failed. Note that after a failed
attempt, the plugin is usually disabled in the configuration and not loaded
again when the editor is restarted.

=cut

sub failed {
	my $self    = shift;
	my $plugins = $self->plugins;
	return grep { $plugins->{$_}->status eq 'error' } keys %$plugins;
}

######################################################################
# PAR Integration

# Attempt to load all plugins that sit as .par files in the
# .padre/plugins/ folder
sub _load_plugins_from_par {
	my ($self) = @_;
	$self->_setup_par;

	my $plugin_dir = $self->plugin_dir;
	opendir my $dh, $plugin_dir or return;
	while ( my $file = readdir $dh ) {
		if ( $file =~ /^\w+\.par$/i ) {

			# Only single-level plugins for now.
			my $parfile = File::Spec->catfile( $plugin_dir, $file );
			PAR->import($parfile);
			$file =~ s/\.par$//i;
			$file =~ s/-/::/g;

			# Caller must refresh plugin menu
			$self->_load_plugin($file);
		}
	}
	closedir($dh);
	return;
}

# Load the PAR module and setup the cache directory.
sub _setup_par {
	my ($self) = @_;

	return if $self->{par_loaded};

	# Setup the PAR environment:
	require PAR;
	my $plugin_dir = $self->plugin_dir;
	my $cache_dir = File::Spec->catdir( $plugin_dir, 'cache' );
	$ENV{PAR_GLOBAL_TEMP} = $cache_dir;
	File::Path::mkpath($cache_dir) unless -e $cache_dir;
	$ENV{PAR_TEMP} = $cache_dir;

	$self->{par_loaded} = 1;
}

######################################################################
# Loading and Unloading a Plugin

=pod

=head2 load_plugin

Given a plugin name such as C<Foo> (the part after Padre::Plugin),
load the corresponding module, enable the plugin and update the Plugins
menu, etc.

=cut

sub load_plugin {
	my $self = shift;
	my $ret  = $self->_load_plugin(@_);
	$self->_refresh_plugin_menu;
	return $ret;
}

# This method implements the actual mechanics of loading a plugin,
# without regard to the context it is being called from.
# So this method doesn't do stuff like refresh the plugin menu.
#
# MAINTAINER NOTE: This method looks fairly long, but it's doing
# a very specific and controlled series of steps. Splitting this up
# would just make the process hardner to understand, so please don't.
sub _load_plugin {
	my $self = shift;
	my $name = shift;

	# If this plugin is already loaded, shortcut and skip
	$name =~ s/^Padre::Plugin:://;
	if ( $self->plugins->{$name} ) {
		return;
	}

	# Create the plugin object (and flush the old sort order)
	my $module = "Padre::Plugin::$name";
	my $plugin = $self->{plugins}->{$name} = Padre::PluginHandle->new(
		name  => $name,
		class => $module,
	);
	delete $self->{plugin_names};

	# Does the plugin load without error
	my $code = "use $module ();";
	eval $code;    ## no critic
	if ($@) {
		$plugin->errstr(
			sprintf(
				Wx::gettext("Plugin:%s - Failed to load module: %s"),
				$name,
				$@,
			)
		);
		$plugin->status('error');
		return;
	}

	# Plugin must be a Padre::Plugin subclass
	unless ( $module->isa('Padre::Plugin') ) {
		$plugin->errstr(
			sprintf(
				Wx::gettext(
					"Plugin:%s - Not compatible with Padre::Plugin API. " . "Need to be subclass of Padre::Plugin"
				),
				$name,
			)
		);
		$plugin->status('error');
		return;
	}

	# Attempt to instantiate the plugin
	my $object = eval { $module->new( $self->{parent} ) };
	if ($@) {
		$plugin->errstr(
			sprintf(
				Wx::gettext("Plugin:%s - Could not instantiate plugin object"),
				$name,
				)
				. ": $@"
		);
		$plugin->status('error');
		return;
	}
	unless ( _INSTANCE( $object, 'Padre::Plugin' ) ) {
		$plugin->errstr(
			sprintf(
				Wx::gettext(
					"Plugin:%s - Could not instantiate plugin object: the constructor does not return a Padre::Plugin object"
				),
				$name,
			)
		);
		$plugin->status('error');
		return;
	}

	# Plugin is now loaded
	$plugin->{object} = $object;
	$plugin->status('loaded');

	# TODO: shall we check this? Padre::Plugin provides this method so every plugin will already have it
	#unless ( $plugin->{object}->can('menu_plugins') ) {
	#}
	my @menus = $plugin->{object}->menu_plugins_simple;
	unless (@menus) {
		$plugin->errstr(
			sprintf(
				Wx::gettext("Plugin:%s - Does not have menus"),
				$name,
			)
		);

		# TODO: for now we allow a plugin without a menu but maybe we should not.
		#$plugin->status('error');
		#return;
	}

	# Should we try to enable the plugin
	my $conf = $self->plugin_db($plugin);
	unless ( defined $conf->{enabled} ) {

		# Do not enable by default
		$conf->{enabled} = 0;
	}
	unless ( $conf->{enabled} ) {
		$plugin->status('disabled');
		return;
	}

	# add a new directory for locale to search translation catalogs.
	my $localedir = $object->plugin_locale_directory
		if $object->can('plugin_locale_directory');
	if ( defined $localedir && -d $localedir ) {
		my $locale = Padre::Current->main->{locale};
		$locale->AddCatalogLookupPathPrefix($localedir);
	}

	# FINALLY we are clear to enable the plugin
	$plugin->enable;

	return 1;
}

=pod

=head2 unload_plugin

Given a plugin name such as C<Foo> (the part after Padre::Plugin),
DISable the plugin, UNload the corresponding module, and update the Plugins
menu, etc.

=cut

sub unload_plugin {
	my $self = shift;
	my $ret  = $self->_unload_plugin(@_);
	$self->_refresh_plugin_menu;
	return $ret;
}

# the guts of unload_plugin which don't refresh the menu
sub _unload_plugin {
	my $self   = shift;
	my $handle = $self->_plugin(shift);

	# Remember if we are enabled or not
	my $enabled = $handle->enabled ? 1 : 0;
	Padre::DB::Plugin->update_enabled(
		$handle->class => $enabled,
	);

	# Disable if needed
	if ( $handle->enabled ) {
		$handle->disable;
	}

	# Destruct the plugin
	if ( defined $handle->{object} ) {
		$handle->{object} = undef;
	}

	# Unload the plugin class itself
	require Class::Unload;
	Class::Unload->unload( $handle->class );

	# Finally, remove the handle (and flush the sort order)
	delete $self->{plugins}->{ $handle->name };
	delete $self->{plugin_names};

	return 1;
}

=pod

=head2 reload_plugin

Reload a single plugin whose name (without C<Padre::Plugin::>)
is passed in as first argument.

=cut

sub reload_plugin {
	my $self = shift;
	my $name = shift;
	$self->_unload_plugin($name);
	$self->load_plugin($name)    or return;
	$self->enable_editors($name) or return;
	return 1;
}

#####################################################################
# Enabling and Disabling a Plugin

# Assume the named plugin exists, enable it
sub _plugin_enable {
	$_[0]->_plugin( $_[1] )->enable;
}

# Assume the named plugin exists, disable it
sub _plugin_disable {
	$_[0]->_plugin( $_[1] )->disable;
}

=pod

=head2 plugin_db

Given a plugin name or namespace, returns a hash reference
which corresponds to the configuration section in the Padre
database of that plugin. Any modifications of that
hash reference will, on normal exit, be serialized and
written back to the databasefile.

If the plugin name is omitted and this method is called from
a plugin namespace, the plugin name is determine automatically.

=cut

sub plugin_db {
	my $self = shift;

	# Infer the plugin name from caller if not provided
	my $param = shift;
	unless ( defined $param ) {
		my ($package) = caller();
		unless ( $package =~ /^Padre::Plugin::/ ) {
			Carp::croak("Cannot infer the name of the plugin for which the configuration has been requested");
		}
		$param = $package;
	}

	# Get the plugin, and from there the config
	my $plugin = $self->_plugin($param);
	my $object = Padre::DB::Plugin->fetch_name( $plugin->class );
	unless ($object) {
		$object = Padre::DB::Plugin->create(
			name    => $plugin->class,
			version => $plugin->version,
			enabled => undef,              # undef means no preference yet
			config  => undef,
		);
	}
	return $object;
}

# enable all the plugins for a single editor
sub editor_enable {
	my ( $self, $editor ) = @_;
	foreach my $name ( keys %{ $self->{plugins} } ) {
		my $plugin = $self->{plugins}->{$name} or return;
		my $object = $plugin->{object}         or return;
		next unless $plugin->{status};
		next unless $plugin->{status} eq 'enabled';
		eval {
			return if not $object->can('editor_enable');
			$object->editor_enable( $editor, $editor->{Document} );
		};
		if ($@) {
			warn $@;

			# TODO: report the plugin error!
		}
	}
	return;
}

sub enable_editors_for_all {
	my $self    = shift;
	my $plugins = $self->plugins;
	foreach my $name ( keys %$plugins ) {
		$self->enable_editors($name);
	}
	return 1;
}

sub enable_editors {
	my $self   = shift;
	my $name   = shift;
	my $plugin = $self->plugins->{$name} or return;
	my $object = $plugin->{object} or return;
	return unless ( $plugin->{status} and $plugin->{status} eq 'enabled' );
	foreach my $editor ( $self->parent->wx->main->editors ) {
		if ( $object->can('editor_enable') ) {
			$object->editor_enable( $editor, $editor->{Document} );
		}
	}
	return 1;
}

######################################################################
# Menu Integration

# Generate the menu for a plugin
sub get_menu {
	my $self   = shift;
	my $main   = shift;
	my $name   = shift;
	my $plugin = $self->_plugin($name);
	unless ( $plugin and $plugin->{status} eq 'enabled' ) {
		return ();
	}
	unless ( $plugin->{object}->can('menu_plugins') ) {
		return ();
	}
	my ( $label, $menu ) = eval { $plugin->{object}->menu_plugins($main) };
	if ($@) {
		$plugin->errstr( Wx::gettext("Error when calling menu for plugin") . "'$name': $@" );
		return ();
	}
	unless ( defined $label and defined $menu ) {
		return ();
	}
	return ( $label, $menu );
}

=pod

=head2 reload_current_plugin

When developing a plugin one usually edits the
files belonging to the plugin (The Padre::Plugin::Wonder itself
or Padre::Documents::Wonder located in the same project as the plugin
itself.

This call and the appropriate menu option should be able to load
(or reload) that plugin.

=cut

sub reload_current_plugin {
	my $self    = shift;
	my $main    = $self->parent->wx->main;
	my $config  = $self->parent->config;
	my $plugins = $self->plugins;

	return $main->error( Wx::gettext('No document open') ) if not $main->current;
	my $filename = $main->current->filename;
	return $main->error( Wx::gettext('No filename') ) if not $filename;

	# TODO: locate project
	my $dir = Padre::Util::get_project_dir($filename);
	return $main->error( Wx::gettext('Could not locate project dir') ) if not $dir;

	# TODO shall we relax the assumption of a lib subdir?
	$dir = File::Spec->catdir( $dir, 'lib' );
	@INC = ( $dir, grep { $_ ne $dir } @INC );

	my ($plugin_filename) = glob File::Spec->catdir( $dir, 'Padre', 'Plugin', '*.pm' );

	# Load plugin
	my $plugin = File::Basename::basename($plugin_filename);
	$plugin =~ s/\.pm$//;

	if ( $plugins->{$plugin} ) {
		$self->reload_plugin($plugin);
	} else {
		$self->load_plugin($plugin);
		if ( $self->plugins->{$plugin}->{status} eq 'error' ) {
			$main->error(
				sprintf(
					Wx::gettext("Failed to load the plugin '%s'\n%s"),
					$plugin, $self->plugins->{$plugin}->errstr
				)
			);
			return;
		}
	}

	return;
}

=pod

=head2 on_context_menu

Called by C<Padre::Wx::Editor> when a context menu is about to
be displayed. The method calls the context menu hooks in all plugins
that have one for plugin-specific manipulation of the context menu.

=cut

sub on_context_menu {
	my $self    = shift;
	my $plugins = $self->plugins_with_context_menu;
	return if not keys %$plugins;

	my ( $doc, $editor, $menu, $event ) = @_;

	my $plugin_handles = $self->plugins;
	foreach my $plugin_name ( keys %$plugins ) {
		my $plugin = $plugin_handles->{$plugin_name}->object;
		$plugin->event_on_context_menu( $doc, $editor, $menu, $event );
	}
	return ();
}

# TODO: document this.
# TODO: make it also reload the file?
sub test_a_plugin {
	my $self    = shift;
	my $main    = $self->parent->wx->main;
	my $config  = $self->parent->config;
	my $plugins = $self->plugins;

	my $last_filename = $main->current->filename;
	my $default_dir   = '';
	if ($last_filename) {
		$default_dir = File::Basename::dirname($last_filename);
	}
	my $dialog = Wx::FileDialog->new(
		$main, Wx::gettext('Open file'), $default_dir, '', '*.*', Wx::wxFD_OPEN,
	);
	unless (Padre::Constant::WIN32) {
		$dialog->SetWildcard("*");
	}
	if ( $dialog->ShowModal == Wx::wxID_CANCEL ) {
		return;
	}
	my $filename = $dialog->GetFilename;
	$default_dir = $dialog->GetDirectory;

	# Save into plugin for next time
	my $file = File::Spec->catfile( $default_dir, $filename );

	# last catfile's parameter is to ensure trailing slash
	my $plugin_folder_name = qr/Padre[\\\/]Plugin[\\\/]/;
	( $default_dir, $filename ) = split( $plugin_folder_name, $file, 2 );
	unless ($filename) {
		Wx::MessageBox(
			sprintf(
				Wx::gettext("Plugin must have '%s' as base directory"),
				$plugin_folder_name
			),
			'Error loading plugin',
			Wx::wxOK, $main
		);
		return;
	}

	$filename =~ s/\.pm$//;        # remove last .pm
	$filename =~ s/[\\\/]/\:\:/;
	unless ( $INC[0] eq $default_dir ) {
		unshift @INC, $default_dir;
	}

	# Unload any previously existant plugin with the same name
	if ( $plugins->{$filename} ) {
		$self->unload_plugin($filename);
		delete $plugins->{$filename};
	}

	# Load the selected plugin
	$self->load_plugin($filename);
	if ( $self->plugins->{$filename}->{status} eq 'error' ) {
		$main->error(
			sprintf(
				Wx::gettext("Failed to load the plugin '%s'\n%s"), $filename, $self->plugins->{$filename}->errstr
			)
		);
		return;
	}

	#$self->reload_plugins;
}

# Refresh the Plugins menu
sub _refresh_plugin_menu {
	$_[0]->parent->wx->main->menu->plugins->refresh;
}

######################################################################
# Support Functions

sub _plugin {
	my ( $self, $it ) = @_;
	if ( _INSTANCE( $it, 'Padre::PluginHandle' ) ) {
		my $current = $self->{plugins}->{ $it->name };
		unless ( defined $current ) {
			Carp::croak("Unknown plugin '$it' provided to PluginManager");
		}
		unless ( Scalar::Util::refaddr($it) == Scalar::Util::refaddr($current) ) {
			Carp::croak("Duplicate plugin '$it' provided to PluginManager");
		}
		return $it;
	}
	if ( defined _CLASS($it) ) {

		# Convert from class to name if needed
		$it =~ s/^Padre::Plugin:://;
	}
	if ( _IDENTIFIER($it) ) {
		unless ( defined $self->{plugins}->{$it} ) {
			Carp::croak("Plugin '$it' does not exist in PluginManager");
		}
		return $self->{plugins}->{$it};
	}
	Carp::croak("Missing or invalid plugin provided to Padre::PluginManager");
}

1;

__END__

=pod

=head1 SEE ALSO

L<Padre>, L<Padre::Config>

L<PAR> for more on the plugin system.

=head1 COPYRIGHT

Copyright 2008-2009 The Padre development team as listed in Padre.pm.

=head1 LICENSE

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl 5 itself.

=cut

# Copyright 2008-2009 The Padre development team as listed in Padre.pm.
# LICENSE
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl 5 itself.

