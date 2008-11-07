#!/usr/bin/perl

use strict;
use warnings;

use FindBin      qw($Bin);
use File::Spec   ();
use Data::Dumper qw(Dumper);

use Test::More tests => 17;

use t::lib::Padre;
use Padre;

use_ok('Padre::PluginManager');

my $padre = Padre->new();
my $plugin_m1 = Padre::PluginManager->new($padre);
isa_ok $plugin_m1, 'Padre::PluginManager';

is $plugin_m1->plugin_dir, Padre::Config->default_plugin_dir;
is keys %{$plugin_m1->plugins}, 0;

ok ! defined($plugin_m1->load_plugins()), 'load_plugins always returns undef';


# check if we have the plugins that come with Padre
is (keys %{$plugin_m1->plugins}, 2);
is $plugin_m1->plugins->{Parrot}, 'Padre::Plugin::Parrot';
is $plugin_m1->plugins->{'Development::Tools'},  'Padre::Plugin::Development::Tools';

# try load again
my $st = $plugin_m1->_load_plugin('Parrot');
is $st, undef;

## Test Part Two With custom plugins
my $custom_dir = File::Spec->catfile( $Bin, 'lib' );
my $plugin_m2  = Padre::PluginManager->new($padre, plugin_dir => $custom_dir);

is $plugin_m2->plugin_dir, $custom_dir;
is keys %{$plugin_m2->plugins}, 0;

$plugin_m2->_load_plugins_from_inc();
is(keys %{$plugin_m2->plugins}, 4, 'correct number of test plugins')
	or diag(Dumper(\$plugin_m2->plugins));

is $plugin_m2->plugins->{Parrot},                'Padre::Plugin::Parrot';
is $plugin_m2->plugins->{'Development::Tools'},  'Padre::Plugin::Development::Tools';
is $plugin_m2->plugins->{TestPlugin},            'Padre::Plugin::TestPlugin';
is $plugin_m2->plugins->{'Test::Plugin'},        'Padre::Plugin::Test::Plugin';

# try load again
$st = $plugin_m2->_load_plugin('TestPlugin');
is $st, undef;

### XXX? TODO, test par

1;