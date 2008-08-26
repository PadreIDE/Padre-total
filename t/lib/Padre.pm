package t::lib::Padre;

# Common testing logic for Padre

use strict;
use warnings;
use File::Temp;

# By default, load Padre in a controlled environment
BEGIN {
    $ENV{PADRE_HOME} = File::Temp::tempdir( CLEANUP => 1 );
}

1;
