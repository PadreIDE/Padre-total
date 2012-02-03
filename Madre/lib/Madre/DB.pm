package Madre::DB;

use 5.008;
use strict;
use ORLite::Migrate 1.09 {
    create       => 1,
    file         => 'data/madre.db',
    timeline     => 'Madre::Timeline',
    user_version => 3,
};

our $VERSION = '0.01';

1;
