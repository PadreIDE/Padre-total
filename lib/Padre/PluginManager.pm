package Padre::PluginManager;
use strict;
use warnings;

use Carp         qw(croak);
use File::Path   ();
use File::Spec   ();
use File::Find::Rule;
use Module::Refresh;

use Wx::Locale qw(:default);

our $VERSION = '0.16';

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
	
	my @dirs = grep {-d $_} map {File::Spec->catdir($_, 'Padre', 'Plugin')} @INC;
	
	my @files = File::Find::Rule->file()->name('*.pm')->in( @dirs );
	foreach my $file (@files) {
		# full path filenames
		$file =~ s/\.pm$//;
		$file =~ s{^.*Padre[/\\]Plugin\W*}{};
		$file =~ s{[/\\]}{::}g;
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

# given a plugin name such as Foo or Foo::Bar (the part after Padre::Plugin),
# load the corresponding module
sub _load_plugin {
	my ($self, $file) = @_;
	my $plugins = $self->plugins;

	# skip if that plugin was already loaded
	return if exists $plugins->{$file};

	my $module = "Padre::Plugin::$file";
	eval "use $module"; ## no critic
	if ($@) {
		warn "ERROR while trying to load plugin '$file': $@";
		return;
	}
	$plugins->{$file} = $module;
	return 1;
}

sub reload_plugins {
    my ( $win ) = @_;

    my $refresher = new Module::Refresh;

    my %plugins = %{ Padre->ide->plugin_manager->plugins };
    foreach my $name ( sort keys %plugins ) {
        # reload the module
        my $file_in_INC = "Padre/Plugin/${name}.pm";
        $file_in_INC =~ s/\:\:/\//;
        $refresher->refresh_module($file_in_INC);
    }
    reload_menu($win);
}

sub reload_menu {
    my ( $win ) = @_;

    # re-create menu,
    my $plugin_menu = $win->{menu}->get_plugin_menu();
    my $plugin_menu_place = $win->{menu}->{wx}->FindMenu( gettext("Pl&ugins") );
    $win->{menu}->{wx}->Replace( $plugin_menu_place, $plugin_menu, gettext("Pl&ugins") );
    
    $win->{menu}->refresh;
    
    Wx::MessageBox( 'done', 'done', Wx::wxOK|Wx::wxCENTRE, $win );
}

sub test_a_plugin {
    my ( $win ) = @_;

    my $plugin_config = Padre->ide->plugin_manager->plugin_config('Development::Tools');
    my $last_filename = $plugin_config->{last_test_plugin_file};
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
    $plugin_config->{last_test_plugin_file} = $file;
    
    ( $default_dir, $filename ) = split(/Padre[\\\/]Plugin[\\\/]/, $file, 2);
    $filename    =~ s/\.pm$//; # remove last .pm
    $filename    =~ s/[\\\/]/\:\:/;
    
    unshift @INC, $default_dir unless ($INC[0] eq $default_dir);
    my $plugins = Padre->ide->plugin_manager->plugins;
    $plugins->{$filename} = "Padre::Plugin::$filename";
    eval { require $file; 1 }; # load for Module::Refresh
    return $win->error( $@ ) if ( $@ );
    
    # reload all means rebuild the 'Plugins' menu
    reload_plugins( $win );
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

