package t::lib::Test;

use strict;
use File::Remove ();

our $VERSION = '0.1';

# TODO: If anyone ever wants to make these tests run in parallel
# you should improve this to use unique test databases.
my $DATABASE = 't/madre.db';
File::Remove::clear($DATABASE);

1;
