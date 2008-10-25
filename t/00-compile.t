use strict;
use warnings;

use Test::More;
eval "use Test::Compile 0.08";
Test::More->builder->BAIL_OUT(
"Test::Compile 1.00 required for testing compilation") if $@;
all_pm_files_ok();