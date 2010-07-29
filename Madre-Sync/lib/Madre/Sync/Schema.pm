package Madre::Sync::Schema;

use Moose;

extends 'DBIx::Class::Schema::Loader';

__PACKAGE__->naming( 'current' );

1;
