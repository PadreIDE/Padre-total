package Padre::DB::Plugin;

use 5.008;
use strict;
use warnings;

our $VERSION = '0.79';

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

Padre::DB::Plugin - Padre::DB class for the plugin table

=head1 DESCRIPTION

TO BE COMPLETED

=head1 METHODS

=head2 base

  # Returns 'Padre::DB'
  my $namespace = Padre::DB::Plugin->base;

Normally you will only need to work directly with a table class,
and only with one ORLite package.

However, if for some reason you need to work with multiple ORLite packages
at the same time without hardcoding the root namespace all the time, you
can determine the root namespace from an object or table class with the
C<base> method.

=head2 table

  # Returns 'plugin'
  print Padre::DB::Plugin->table;

While you should not need the name of table for any simple operations,
from time to time you may need it programatically. If you do need it,
you can use the C<table> method to get the table name.

=head2 load

  my $object = Padre::DB::Plugin->load( $name );

If your table has single column primary key, a C<load> method will be
generated in the class. If there is no primary key, the method is not
created.

The C<load> method provides a shortcut mechanism for fetching a single
object based on the value of the primary key. However it should only
be used for cases where your code trusts the record to already exists.

It returns a C<Padre::DB::Plugin> object, or throws an exception if the
object does not exist.

=head2 select

  # Get all objects in list context
  my @list = Padre::DB::Plugin->select;
  
  # Get a subset of objects in scalar context
  my $array_ref = Padre::DB::Plugin->select(
      'where name > ? order by name',
      1000,
  );

The C<select> method executes a typical SQL C<SELECT> query on the
plugin table.

It takes an optional argument of a SQL phrase to be added after the
C<FROM plugin> section of the query, followed by variables
to be bound to the placeholders in the SQL phrase. Any SQL that is
compatible with SQLite can be used in the parameter.

Returns a list of B<Padre::DB::Plugin> objects when called in list context, or a
reference to an C<ARRAY> of B<Padre::DB::Plugin> objects when called in scalar
context.

Throws an exception on error, typically directly from the L<DBI> layer.

=head2 iterate

  Padre::DB::Plugin->iterate( sub {
      print $_->name . "\n";
  } );

The C<iterate> method enables the processing of large tables one record at
a time without loading having to them all into memory in advance.

This plays well to the strength of SQLite, allowing it to do the work of
loading arbitrarily large stream of records from disk while retaining the
full power of Perl when processing the records.

The last argument to C<iterate> must be a subroutine reference that will be
called for each element in the list, with the object provided in the topic
variable C<$_>.

This makes the C<iterate> code fragment above functionally equivalent to the
following, except with an O(1) memory cost instead of O(n).

  foreach ( Padre::DB::Plugin->select ) {
      print $_->name . "\n";
  }

You can filter the list via SQL in the same way you can with C<select>.

  Padre::DB::Plugin->iterate(
      'order by ?', 'name',
      sub {
          print $_->name . "\n";
      }
  );

You can also use it in raw form from the root namespace for better control.
Using this form also allows for the use of arbitrarily complex queries,
including joins. Instead of being objects, rows are provided as C<ARRAY>
references when used in this form.

  Padre::DB->iterate(
      'select name from plugin order by name',
      sub {
          print $_->[0] . "\n";
      }
  );

=head2 count

  # How many objects are in the table
  my $rows = Padre::DB::Plugin->count;
  
  # How many objects 
  my $small = Padre::DB::Plugin->count(
      'where name > ?',
      1000,
  );

The C<count> method executes a C<SELECT COUNT(*)> query on the
plugin table.

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

Returns a new L<Padre::DB::Plugin> object.

=head2 create

  my $object = Padre::DB::Plugin->create(

      name => 'value',

      version => 'value',

      enabled => 'value',

      config => 'value',

  );

The C<create> constructor is a one-step combination of C<new> and
C<insert> that takes the column parameters, creates a new
L<Padre::DB::Plugin> object, inserts the appropriate row into the
L<plugin> table, and then returns the object.

If the primary key column C<name> is not provided to the
constructor (or it is false) the object returned will have
C<name> set to the new unique identifier.
 
Returns a new L<plugin> object, or throws an exception on
error, typically from the L<DBI> layer.

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

When used on an existing B<Padre::DB::Plugin> instance, the C<delete> method
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

=head1 ACCESSORS

=head2 name

  if ( $object->name ) {
      print "Object has been inserted\n";
  } else {
      print "Object has not been inserted\n";
  }

Returns true, or throws an exception on error.

REMAINING ACCESSORS TO BE COMPLETED

=head1 SQL

The plugin table was originally created with the
following SQL command.

  CREATE TABLE plugin (
      name VARCHAR(255) PRIMARY KEY,
      version VARCHAR(255),
      enabled BOOLEAN,
      config TEXT
  )

=head1 SUPPORT

Padre::DB::Plugin is part of the L<Padre::DB> API.

See the documentation for L<Padre::DB> for more information.

=head1 AUTHOR

Adam Kennedy E<lt>adamk@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright 2008-2011 The Padre development team as listed in Padre.pm.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut

# Copyright 2008-2011 The Padre development team as listed in Padre.pm.
# LICENSE
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl 5 itself.
