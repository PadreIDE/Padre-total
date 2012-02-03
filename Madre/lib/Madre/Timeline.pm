package Madre::Timeline;

use 5.008;
use strict;
use ORLite::Migrate::Timeline ();

our $VERSION = '0.01';
our @ISA     = 'ORLite::Migrate::Timeline';

sub upgrade1 {
   my $self = shift;

   $self->do(<<'END_SQL');
   CREATE TABLE user ( 
       user_id  INTEGER  NOT NULL PRIMARY KEY,
       email    TEXT     NOT NULL,
       password TEXT     NOT NULL,
       created  DATETIME NOT NULL DEFAULT ( datetime('now') ),
   )
END_SQL

   $self->do(<<'END_SQL');
   CREATE UNIQUE INDEX index_user_email ON user ( email COLLATE NOCASE )
END_SQL

   return 1;
}

sub upgrade2 {
   my $self = shift;

   $self->do(<<'END_SQL');
   CREATE TABLE config (
       config_id INTEGER  NOT NULL PRIMARY KEY,
       user_id   INTEGER  NOT NULL,
       data      BLOB     NOT NULL,
       modified  DATETIME NOT NULL DEFAULT ( datetime('now') ),
       FOREIGN KEY( user_id ) REFERENCES user ( user_id ) ON DELETE CASCADE
   )
END_SQL

   $self->do(<<'END_SQL');
   CREATE INDEX index_config_user_id ON config ( user_id );
END_SQL

   $self->do(<<'END_SQL');
   CREATE INDEX index_config_modified ON config ( modified );
END_SQL

   return 1;
}

sub upgrade3 {
   my $self = shift;

   $self->do(<<'END_SQL');
   CREATE TABLE instance (
      instance_id TEXT     NOT NULL PRIMARY KEY,
      created     DATETIME NOT NULL DEFAULT ( datetime('now') ),
      modified    DATETIME NOT NULL DEFAULT ( datetime('now') ),
      padre       TEXT     NULL
      perl        TEXT     NULL,
      osname      TEXT     NULL,
      data        BLOB     NULL
   )
END_SQL

   return 1;
}

1;
