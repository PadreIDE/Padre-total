package Madre::DB;

use 5.008;
use strict;
use ORLite {
    file    => 'data/madre.db',
    create  => sub {
        my $dbh = shift;

        $dbh->do( q|
            CREATE TABLE user ( 
                id INTEGER NOT NULL PRIMARY KEY ,
                username TEXT UNIQUE NOT NULL,
                password TEXT NOT NULL,
                email TEXT NOT NULL,
                created DATETIME NOT NULL DEFAULT (datetime('now'))
            )
        | );

        $dbh->do( q|
            CREATE TABLE config (
                user_id INTEGER NOT NULL,
                data BLOB,
                modified DATETIME NOT NULL DEFAULT (datetime('now')),
                FOREIGN KEY(user_id) REFERENCES user(userid)
            )
        | );
    }
};

our $VERSION = '0.01';

1;
