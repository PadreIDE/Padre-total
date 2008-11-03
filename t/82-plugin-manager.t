#!/usr/bin/perl

use strict;
use warnings;
use Test::More tests => 11;
use t::lib::Padre;
use FindBin qw/$Bin/;
use File::Spec ();

use Padre;
use_ok('Padre::PluginManager');

my $padre = Padre->new();
my $plugin_m1 = Padre::PluginManager->new($padre);

is $plugin_m1->plugin_dir, Padre::Config->default_plugin_dir;
is keys %{$plugin_m1->plugins}, 0;

$plugin_m1->load_plugins();

# at least, we have Plugin/Parrot.pm
cmp_ok(keys %{$plugin_m1->plugins}, '>', 0);
is $plugin_m1->plugins->{Parrot}, 'Padre::Plugin::Parrot';

# try load again
my $st = $plugin_m1->_load_plugin('Parrot');
is $st, undef;

## Test Part Two With custom plugins
my $custom_dir = File::Spec->catfile( $Bin, 'lib' );
my $plugin_m2  = Padre::PluginManager->new($padre, plugin_dir => $custom_dir);

is $plugin_m2->plugin_dir, $custom_dir;
is keys %{$plugin_m2->plugins}, 0;

$plugin_m2->_load_plugins_from_inc();
cmp_ok(keys %{$plugin_m2->plugins}, '>', 0);
#use Data::Dumper;
#diag(Dumper(\$plugin_m2->plugins));
is $plugin_m2->plugins->{TestPlugin}, 'Padre::Plugin::TestPlugin';

# try load again
$st = $plugin_m2->_load_plugin('TestPlugin');
is $st, undef;

### XXX? TODO, test par

1;