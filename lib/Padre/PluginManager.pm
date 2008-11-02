package Padre::PluginManager;
use strict;
use warnings;
use File::Path ();
use File::Spec ();
use Carp       qw(croak);

our $VERSION = '0.15';

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
	return;
}

sub _load_plugins_from_inc {
	my ($self) = @_;

	# Try the plugin directory first:
	my $plugin_dir = $self->plugin_dir;
	unshift @INC, $plugin_dir unless grep {$_ eq $plugin_dir} @INC;

	foreach my $path (@INC) {
		my $dir = File::Spec->catdir($path, 'Padre', 'Plugin');
		opendir my $dh, $dir or next;
		while (my $file = readdir $dh) {
			if ($file =~ /^\w+\.pm$/) {
				$file =~ s/\.pm$//;
				$self->_load_plugin($file);
			}
		}
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
			my $parfile = File::Spec->catfile($plugin_dir, $file);
			$file =~ s/\.par$//i;
			PAR->import($parfile);
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

# given a file name (Foo.pm), load the corresponding module
sub _load_plugin {
	my ($self, $file) = @_;
	my $plugins = $self->plugins;
	delete $plugins->{$file};
	
	my $module = "Padre::Plugin::$file";

	# skip if that plugin was already loaded
	my $inc_file = $module.".pm";
	$inc_file =~ s/::/\//g;
	return if exists $INC{$inc_file};

	eval "use $module"; ## no critic
	if ($@) {
		warn "ERROR while trying to load plugin '$file': $@";
		return();
	}
	$plugins->{$file} = $module;
	return 1;
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

