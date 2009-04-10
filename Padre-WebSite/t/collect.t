use strict;
use warnings;

use Test::Most;
use lib '/home/gabor/work/Test-Snapshots/lib';
use Test::Snapshots;

Test::Snapshots::debug(1);
Test::Snapshots::set_glob('*.pl');
Test::Snapshots::set_accessories_dir('t/files');

#Test::Snapshots::multiple_setups('*.out');

bail_on_fail;

test_all_snapshots('script');

