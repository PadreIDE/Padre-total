package Madre::Sync::Schema;

use Moose;
use namespace::autoclean;

our $VERSION = '0.01';

BEGIN {
	extends 'DBIx::Class::Schema::Loader';
}

__PACKAGE__->naming( 'current' );

__PACKAGE__->meta->make_immutable;

1;
