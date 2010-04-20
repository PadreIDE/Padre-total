package Padre::DB::Plugin;

use 5.008;
use strict;
use warnings;

our $VERSION = '0.60';

# Finds and returns a single element by name
sub fetch_name {
	return ( $_[0]->select( 'where name = ?', $_[1] ) )[0];
}

# Set enabled for an object
sub update_enabled {
	Padre::DB->do(
		'update plugin set enabled = ? where name = ?', {},
		$_[2], $_[1],
	);
}

1;

__END__

=pod

=head1 NAME

Padre::DB::Plugin - L<Padre::DB> class for the C<plugin> table

=head1 SYNOPSIS

TO BE COMPLETED

=head1 DESCRIPTION

TO BE COMPLETED

=head1 METHODS

=head2 select

  # Get all objects in list context
  my @list = Padre::DB::Plugin->select;

  # Get a subset of objects in scalar context
  my $array_ref = Padre::DB::Plugin->select(
      'where name > ? order by name',
      1000,
  );

The C<select> method executes a typical SQL C<SELECT> query on the
C<plugin> table.

It takes an optional argument of a SQL phrase to be added after the
C<FROM plugin> section of the query, followed by variables
to be bound to the placeholders in the SQL phrase. Any SQL that is
compatible with SQLite can be used in the parameter.

Returns a list of C<Padre::DB::Plugin> objects when called in list context, or a
reference to an ARRAY of C<Padre::DB::Plugin> objects when called in scalar context.

Throws an exception on error, typically directly from the L<DBI> layer.

=head2 count

  # How many objects are in the table
  my $rows = Padre::DB::Plugin->count;

  # How many objects
  my $small = Padre::DB::Plugin->count(
      'where name > ?',
      1000,
  );

The C<count> method executes a C<SELECT COUNT(*)> query on the
C<plugin> table.

It takes an optional argument of a SQL phrase to be added after the
C<FROM plugin> section of the query, followed by variables
to be bound to the placeholders in the SQL phrase. Any SQL that is
compatible with SQLite can be used in the parameter.

Returns the number of objects that match the condition.

Throws an exception on error, typically directly from the L<DBI> layer.

=head2 new

TO BE COMPLETED

The C<new> constructor is used to create a new abstract object that
is not (yet) written to the database.

Returns a new C<Padre::DB::Plugin> object.

=head2 create

  my $object = Padre::DB::Plugin->create(
      name    => 'value',
      version => 'value',
      enabled => 'value',
      config  => 'value',
  );

The C<create> constructor is a one-step combination of C<new> and
C<insert> that takes the column parameters, creates a new
C<Padre::DB::Plugin> object, inserts the appropriate row into the C<plugin>
table, and then returns the object.

If the primary key column C<name> is not provided to the
constructor (or it is false) the object returned will have
C<name> set to the new unique identifier.

Returns a new C<plugin> object, or throws an exception on error,
typically from the L<DBI> layer.

=head2 insert

  $object->insert;

The C<insert> method commits a new object (created with the C<new> method)
into the database.

If a the primary key column C<name> is not provided to the
constructor (or it is false) the object returned will have
C<name> set to the new unique identifier.

Returns the object itself as a convenience, or throws an exception
on error, typically from the L<DBI> layer.

=head2 delete

  # Delete a single instantiated object
  $object->delete;

  # Delete multiple rows from the plugin table
  Padre::DB::Plugin->delete('where name > ?', 1000);

The C<delete> method can be used in a class form and an instance form.

When used on an existing C<Padre::DB::Plugin> instance, the C<delete> method
removes that specific instance from the C<plugin>, leaving
the object intact for you to deal with post-delete actions as you wish.

When used as a class method, it takes a compulsory argument of a SQL
phrase to be added after the C<DELETE FROM plugin> section
of the query, followed by variables to be bound to the placeholders
in the SQL phrase. Any SQL that is compatible with SQLite can be used
in the parameter.

Returns true on success or throws an exception on error, or if you
attempt to call delete without a SQL condition phrase.

=head2 truncate

  # Delete all records in the plugin table
  Padre::DB::Plugin->truncate;

To prevent the common and extremely dangerous error case where
deletion is called accidentally without providing a condition,
the use of the C<delete> method without a specific condition
is forbidden.

Instead, the distinct method C<truncate> is provided to delete
all records in a table with specific intent.

Returns true, or throws an exception on error.

=head1 INTERFACE

=head2 Accessors

=head3 name

  if ( $object->name ) {
      print "Object has been inserted\n";
  } else {
      print "Object has not been inserted\n";
  }

Returns true, or throws an exception on error.


  REMAINING ACCESSORS TO BE COMPLETED

=head2 SQL

The C<plugin> table was originally created with the
following SQL command.

  CREATE TABLE plugin (
  	name VARCHAR(255) PRIMARY KEY,
  	version VARCHAR(255),
  	enabled BOOLEAN,
  	config TEXT
  )

=head1 SUPPORT

C<Padre::DB::Plugin> is part of the L<Padre::DB> API.

See the documentation for L<Padre::DB> for more information.

=head1 AUTHOR

Adam Kennedy

=head1 COPYRIGHT

Copyright 2008-2010 The Padre development team as listed in Padre.pm.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut

# Copyright 2008-2010 The Padre development team as listed in Padre.pm.
# LICENSE
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl 5 itself.
