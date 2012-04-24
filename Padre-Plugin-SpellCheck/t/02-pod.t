#!/usr/bin/env perl

# Test that the syntax of our POD documentation is valid
use strict;
use warnings;
$| = 1;

use Test::More;
eval "use Test::Pod 1.45";
plan skip_all => "Test::Pod 1.45 required for testing POD" if $@;
all_pod_files_ok();

done_testing();

1;

__END__

