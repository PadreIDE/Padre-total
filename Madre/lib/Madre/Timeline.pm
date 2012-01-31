package Madre::Timeline;

use 5.008;
use strict;
use ORLite::Migrate::Timeline ();

our $VERSION = '0.01';
our @ISA     = 'ORLite::Migrate::Timeline';

sub upgrade1 { $_[0]->do(<<'END_SQL') }
CREATE TABLE user ( 
    id INTEGER NOT NULL PRIMARY KEY,
    username TEXT UNIQUE NOT NULL,
    password TEXT NOT NULL,
    email TEXT NOT NULL,
    created DATETIME NOT NULL DEFAULT ( datetime('now') )
)
END_SQL

sub upgrade2 { $_[0]->do(<<'END_SQL') }
CREATE TABLE config (
    user_id INTEGER NOT NULL,
    data BLOB,
    modified DATETIME NOT NULL DEFAULT ( datetime('now') ),
    FOREIGN KEY( user_id ) REFERENCES user( userid )
)
END_SQL

sub upgrade3 { $_[0]->do(<<'END_SQL') }
CREATE TABLE ping (
   ping_id INTEGER NOT NULL PRIMARY KEY,
   data BLOB,
   created DATETIME NOT NULL DEFAULT ( datetime('now') )
)
END_SQL

1;
