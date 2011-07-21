use strict;
use warnings;

use Test::More tests => 1;

# the debugger loads custom settings from
# a .perldb file. If the user has it, some
# test outputs might go boo boo.
use File::HomeDir;
use File::Spec;
my $rc_file = -e File::Spec->catfile(
    File::HomeDir->my_home,
    '.perldb'
);

if ($rc_file) {
    diag('');
    diag('***************************************');
    diag('** YOU SEEM TO HAVE A ".perldb" FILE **');
    diag('** IN YOUR HOME DIRECTORY. IF YOU    **');
    diag('** SEE TEST FAILURES, PLEASE MOVE IT **');
    diag('** SOMEWHERE ELSE, TRY AGAIN AND     **');
    diag('** RESTORE IT AFTER INSTALLATION.    **');
    diag('***************************************');
}

ok 1;
