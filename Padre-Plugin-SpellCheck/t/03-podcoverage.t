#!/usr/bin/env perl

# Ensure pod coverage in your distribution
use strict;
use warnings;
$| = 1;

use Test::More;

eval "use Test::Pod::Coverage 1.08";
plan skip_all => "Test::Pod::Coverage 1.08 required for testing POD coverage" if $@;

# Define the three overridden methods.
my $trustme = { trustme => [qr/^(TRACE)$/] };

pod_coverage_ok( "Padre::Plugin::SpellCheck", $trustme );
pod_coverage_ok( "Padre::Plugin::SpellCheck::Checker", $trustme );
pod_coverage_ok( "Padre::Plugin::SpellCheck::Engine", $trustme );
pod_coverage_ok( "Padre::Plugin::SpellCheck::Preferences", $trustme );

done_testing();

1;

__END__
