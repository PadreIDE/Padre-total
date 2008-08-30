package Padre::PluginManager;

# Miscellaneous plugin functionality for Padre

use strict;
use warnings;
use File::Path ();
use File::Spec ();
use Carp       qw(croak);

our $VERSION = '0.06';


sub new {
    my $class = shift;
    my $padre = shift || Padre->new();

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
sub plugin_dir { $_[0]->{plugin_dir} }

sub plugins { $_[0]->{plugins} }

##############

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
    $plugins->{$file} = 0;
    
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
