package Padre::PluginManager;
use strict;
use warnings;

use Carp         qw(croak);
use File::Path   ();
use File::Spec   ();
use File::Find::Rule;

use Padre::Wx    ();
use Padre::Util  ();
use Wx::Locale qw(:default);

our $VERSION = '0.17';

=pod

=head1 NAME

Padre::PluginManager - Padre plugin manager

=head1 DESCRIPTION

The PluginManager class contains logic for locating and loading Padre
plugins, as well as providing part of the interface to plugin writers.

=head1 METHODS

=cut

=head2 new

The constructor returns a new Padre::PluginManager object, but
you should normally access it via the main Padre object:

  my $manager = Padre->ide->plugin_manager;

First argument should be a Padre object.

=cut

sub new {
	my $class = shift;
	my $padre = shift || Padre->ide;

	if (not $padre or not $padre->isa("Padre")) {
		croak("Creation of a Padre::PluginManager without a Padre not possible");
	}

	my $self  = bless {
		plugins => {},
		plugin_dir => Padre::Config->default_plugin_dir,
	  
		par_loaded => 0,
		@_
	}, $class;

	return $self;
}

#############
# ACCESSORS
#

=head2 plugin_dir

Returns the user plugin directory (below the Padre configuration directory).
This directory was added to the C<@INC> module search path and may contain
packaged plugins as PAR files.

=cut

sub plugin_dir { $_[0]->{plugin_dir} }

=head2 plugins

Returns a hash (reference) of plugin names associated with their
implementing module names.

This hash is only populated after C<load_plugins()> was called.

=cut

sub plugins { $_[0]->{plugins} }

=head2 plugin_config

Given a plugin name or namespace, returns a hash reference
which corresponds to the configuration section in the Padre
YAML configuration of that plugin. Any modifications of that
hash reference will, on normal exit, be written to the
configuration file.

If the plugin name is omitted and this method is called from
a plugin namespace, the plugin name is determine automatically.

=cut

sub plugin_config {
	my $self = shift;
	my $plugin = shift;

	# infer the plugin name from caller
	if (not defined $plugin) {
		my ($package) = caller();
		croak("Cannot infer the name of the plugin for which the configuration has been requested")
			if $package !~ /^Padre::Plugin::/;
		$plugin = $package;
	}

	$plugin =~ s/^Padre::Plugin:://;
	my $padre_config = Padre->ide->config;
	my $plugin_config = $padre_config->{plugins};
	$plugin_config->{$plugin} ||= {};
	return $plugin_config->{$plugin};
}

##############

=head2 load_plugins

Scans for new plugins in the user plugin directory, in C<@INC>,
and in C<.par> files in the user plugin directory.

Loads any given module only once, i.e. does not refresh if the
plugin has changed while Padre was running.

=cut

sub load_plugins {
	my ($self) = @_;
	$self->_load_plugins_from_inc();
	$self->_load_plugins_from_par();
	if (my @failed = $self->failed) {
		Padre->ide->wx->main_window->error("Failed to load the following plugin(s):\n" . join "\n", @failed);
		return;
    }

	return;
}

sub failed {
	my ($self) = @_;
	my $plugins = $self->plugins;
	return grep { $plugins->{$_}{status} eq 'failed' } keys %$plugins;
}

sub _load_plugins_from_inc {
	my ($self) = @_;

	# Try the plugin directory first:
	my $plugin_dir = $self->plugin_dir;
	unshift @INC, $plugin_dir unless grep {$_ eq $plugin_dir} @INC;
	
	my @dirs = grep {-d $_} map {File::Spec->catdir($_, 'Padre', 'Plugin')} @INC;
	
	my @files = File::Find::Rule->file()->name('*.pm')->maxdepth(1)->in( @dirs );
	foreach my $file (@files) {
		# full path filenames
		$file =~ s/\.pm$//;
		$file =~ s{^.*Padre[/\\]Plugin\W*}{};
		$file =~ s{[/\\]}{::}g;

		# TODO maybe we should report to the user the fact
		# that we changed the name of the MY plugin and she should
		# rename the original one and remove the MY.pm from his installation
		next if $file eq 'MY';

		$self->_load_plugin($file); # Foo::Bar names
	}

	return;
}

sub _load_plugins_from_par {
	my ($self) = @_;
	$self->_setup_par();

	my $plugin_dir = $self->plugin_dir();
	opendir my $dh, $plugin_dir or return;
	while (my $file = readdir $dh) {
		if ($file =~ /^\w+\.par$/i) {
                # only single-level plugins for now.
		#if ($file =~ /^[\w-]+\.par$/i) {
			my $parfile = File::Spec->catfile($plugin_dir, $file);
			PAR->import($parfile);
			$file =~ s/\.par$//i;
			$file =~ s/-/::/g;
			$self->_load_plugin($file);
		}
	}
	closedir($dh);
	return;
}

sub _setup_par {
	my ($self) = @_;

	return if $self->{par_loaded};

	require PAR;
	# setup the PAR environment:
	my $plugin_dir = $self->plugin_dir;
	my $cache_dir = File::Spec->catdir($plugin_dir, 'cache');
	$ENV{PAR_GLOBAL_TEMP} = $cache_dir;
	File::Path::mkpath($cache_dir) if not -e $cache_dir;
	$ENV{PAR_TEMP} = $cache_dir;

	$self->{par_loaded} = 1;
	return();
}

# given a plugin name such as Foo or Foo::Bar (the part after Padre::Plugin),
# load the corresponding module
sub _load_plugin {
	my ($self, $plugin_name) = @_;
	my $plugins = $self->plugins;

	# skip if that plugin was already loaded
	return if exists $plugins->{$plugin_name};

	my $module = "Padre::Plugin::$plugin_name";
	my $config = Padre->ide->config;

	$plugins->{$plugin_name}{module} = $module;

	if ( not $config->{plugins}{$plugin_name} ) {
		$config->{plugins}{$plugin_name}{enabled} = 0;
		$plugins->{$plugin_name}{status} = 'new';
		return;
	}
	
	if (not $config->{plugins}{$plugin_name}{enabled} ) {
		$plugins->{$plugin_name}{status} = 'disabled';
		return;
	}
	#print "use $module\n";	
	eval "use $module"; ## no critic
	if ($@) {
		warn "ERROR while trying to load plugin '$plugin_name': $@";
		$plugins->{$plugin_name}{status} = 'failed';
		return;
	}

	eval {
		$self->{_objects_}{$plugin_name} = $module->new;
		$self->{_objects_}{$plugin_name}->plugin_enable;
# this now causes trouble
#		foreach my $editor ( Padre->ide->wx->main_window->pages ) {
#			$self->{_objects_}{$plugin_name}->editor_enable( $editor, $editor->{Document} );
#		}
	};
	if ($@) {
		# TODO report error in a nicer way
		warn "ERROR $@";
		$plugins->{$plugin_name}{status} = 'failed';
		# automatically disable the plugin
		$config->{plugins}{$plugin_name}{enabled} = 0;
	} else {
		$plugins->{$plugin_name}{status} = 'loaded';
	}
	
	return 1;
}

sub reload_plugins {
    my ( $win ) = @_;

	require Module::Refresh;
    my $refresher = Module::Refresh->new;

    my %plugins = %{ Padre->ide->plugin_manager->plugins };
    foreach my $name ( sort keys %plugins ) {
		reload_module( $refresher, $name );
    }
    reload_menu($win);
}

sub reload_plugin {
	my ( $win, $name ) = @_;
	
	require Module::Refresh;
	my $refresher = Module::Refresh->new;
	reload_module( $refresher, $name );
	reload_menu($win);
	return;
}

sub reload_module {
    my ( $refresher, $name ) = @_;
	my $file_in_INC = "Padre/Plugin/${name}.pm";
	$file_in_INC =~ s/\:\:/\//;
	$refresher->refresh_module($file_in_INC);
	return;
}


sub reload_menu {
    my ( $win ) = @_;

    # re-create menu,
    my $plugin_menu = $win->{menu}->menu_plugin( $win );
    my $plugin_menu_place = $win->{menu}->{wx}->FindMenu( gettext("Pl&ugins") );
    $win->{menu}->{wx}->Replace( $plugin_menu_place, $plugin_menu, gettext("Pl&ugins") );
    
    $win->{menu}->refresh;
    
    Wx::MessageBox( 'done', 'done', Wx::wxOK|Wx::wxCENTRE, $win );
}

sub test_a_plugin {
    my ( $win ) = @_;

    my $config = Padre->ide->config;
    my $last_filename = $config->{last_test_plugin_file};
    $last_filename  ||= $win->selected_filename;
    my $default_dir;
    if ($last_filename) {
        $default_dir = File::Basename::dirname($last_filename);
    }
    my $dialog = Wx::FileDialog->new(
        $win, gettext('Open file'), $default_dir, '', '*.*', Wx::wxFD_OPEN,
    );
    unless ( Padre::Util::WIN32 ) {
        $dialog->SetWildcard("*");
    }
    if ( $dialog->ShowModal == Wx::wxID_CANCEL ) {
        return;
    }
    my $filename = $dialog->GetFilename;
    $default_dir = $dialog->GetDirectory;
    
    my $file = File::Spec->catfile($default_dir, $filename);
    
    # save into plugin for next time
    $config->{last_test_plugin_file} = $file;
    
    ( $default_dir, $filename ) = split(/Padre[\\\/]Plugin[\\\/]/, $file, 2);
    $filename    =~ s/\.pm$//; # remove last .pm
    $filename    =~ s/[\\\/]/\:\:/;
    
    unshift @INC, $default_dir unless ($INC[0] eq $default_dir);
    my $plugins = Padre->ide->plugin_manager->plugins;

    # load plugin
    delete $plugins->{$filename};
    $config->{plugins}{$filename}{enabled} = 1;
    _load_plugin( Padre->ide->plugin_manager, $filename );
    if (Padre->ide->plugin_manager->plugins->{$filename}->{status} eq 'failed') {
		Padre->ide->wx->main_window->error("Faild to load the plugin '$filename'");
		return;
    }

    # reload all means rebuild the 'Plugins' menu
    reload_plugins( $win );
}

# fetch main menu label for specific plugin
#sub get_label {
#	my ($self, $name) = @_;
#	
#	my $plugins = $self->plugins;
#
#	my $label = '';
#	if ($plugins->{$name}{module}->can('plugins_menu_label')) {
#		$label = eval { $plugins->{$name}{module}->can('plugins_menu_label') };
#		# TODO error handling
#	} else {
#		# TODO report lack of plugins_menu_label
#		# TODO remove support for menu_name in 0.19
#		if ( $plugins->{$name} and $plugins->{$name}{module}->can('menu_name') ) {
#			$label = $plugins->{$name}{module}->menu_name;
#		} else {
#			$label = $name;
#			$label =~ s/::/ /;
#		}
#	}
#	return $label;
#}
#
#sub get_menu {
#	my ($self, $name) = @_;
#
#	my $plugins = $self->plugins;
#	my $menu;
#	if ( $plugins->{$name}{module}->can('menu_plugins') ) {
#		$menu = eval { $plugins->{$name}{module}->menu_plugins; };
#		# TODO error handling ?
#		# TODO combaility with pre 0.18 plugins?
#	}
#	return $menu;
#}
#

sub get_menu {
	my ($self, $win, $name) = @_;

	my $plugins = $self->plugins;

	# TODO add new Padre::Plugin menu creation system
	# in 0.19 remove support for old menu
	my ($label, $items, $menu, @data);
	use Data::Dumper;
	if ($plugins->{$name}{module}->can('menu_plugins_simple') ) {
		($label, $items) = eval { $plugins->{$name}{module}->menu_plugins_simple };
		print Dumper $items;
		if ( $@ ) {
			warn "Error when calling menu for plugin '$name' $@";
			return ();
		}
		# TODO better error handling
		$menu = eval { $plugins->{$name}{module}->menu_plugins($label, $win, [$items]) };
	} else {
		warn "plugins_menu_data is not implemented in plugin '$name'\n";
	} 
	return ($label, $menu);
}

1;

__END__

=pod

=head1 SEE ALSO

L<Padre>, L<Padre::Config>

L<PAR> for more on the plugin system.

=head1 COPYRIGHT

Copyright 2008 Gabor Szabo.

=head1 LICENSE

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl 5 itself.

=cut

