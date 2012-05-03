#!/usr/bin/env perl

# Ensure pod coverage in your distribution
use strict;
use warnings;
$| = 1;

use Test::More;

eval "use Test::Pod::Coverage 1.08";
plan skip_all => "Test::Pod::Coverage 1.08 required for testing POD coverage" if $@;

# Define the overridden methods.
my $trustme = { trustme => [qr/^(TRACE)$/] };

pod_coverage_ok( 'Padre::Plugin::Cookbook', $trustme );
pod_coverage_ok( 'Padre::Plugin::Cookbook::Recipe01::Main', $trustme );
pod_coverage_ok( 'Padre::Plugin::Cookbook::Recipe02::Main', $trustme );
pod_coverage_ok( 'Padre::Plugin::Cookbook::Recipe03::Main', $trustme );
pod_coverage_ok( 'Padre::Plugin::Cookbook::Recipe03::About', $trustme );
pod_coverage_ok( 'Padre::Plugin::Cookbook::Recipe04::Main', $trustme );
pod_coverage_ok( 'Padre::Plugin::Cookbook::Recipe04::About', $trustme );

done_testing();

1;

__END__

