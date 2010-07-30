#!/usr/bin/env perl
 
use strict;
use warnings;

use DBIx::Class::Schema::Loader qw/ make_schema_at /;
make_schema_at(
   'Madre::Sync::Schema',
   {  
      debug => 0,
      dump_directory => '../lib/', 
   },
   [ 'dbi:SQLite:db/data.db' ],
);

