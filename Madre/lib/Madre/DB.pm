package Madre::DB;

use ORLite {
      file         => 'data/madre.db',
      create       => sub {
                            my $dbh = shift;
                            
                            $dbh->do(q|
                                CREATE TABLE user ( 
                                    id INTEGER NOT NULL PRIMARY KEY ,
                                    username TEXT UNIQUE NOT NULL,
                                    password TEXT NOT NULL,
                                    email TEXT NOT NULL
                                )
                            |);
                            
                            $dbh->do(q|
                                CREATE TABLE config (
                                    user_id INTEGER NOT NULL,
                                    config BLOB,
                                    modified DATETIME
                                )
                            |);
                            
                        }
};

1;
