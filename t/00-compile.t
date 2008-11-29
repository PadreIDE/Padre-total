use strict;
use warnings;
use Test::NeedsDisplay;

use Test::More;
plan skip_all => 'Needs Test::Compile 0.08 but that does not work on Windows' if $^O =~ /win/i;
plan skip_all => 'Needs Test::Compile 0.08' if not eval "use Test::Compile 0.08; 1";
diag "Test::Compile $Test::Compile::VERSION";

use File::Temp;
$ENV{PADRE_HOME} = File::Temp::tempdir( CLEANUP => 1 );
all_pl_files_ok(all_pm_files());
