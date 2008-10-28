use strict;
use warnings;

use Test::More;
plan skip_all => 'Needs Test::Compile 0.08' if not eval "use Test::Compile 0.08; 1";
diag "Test::Compile $Test::Compile::VERSION";
all_pl_files_ok(all_pm_files());
