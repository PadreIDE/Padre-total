#!/usr/bin/env perl

use strict;
use Test::More;

eval "use Test::Pod::Coverage 1.08";
plan skip_all => "Test::Pod::Coverage 1.08 required for testing POD coverage" if $@;
all_pod_coverage_ok();

done_testing();

1;

__END__