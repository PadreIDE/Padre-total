package Madre::Sync::Schema::Result::Role;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

Madre::Sync::Schema::Result::Role

=cut

__PACKAGE__->table("roles");

=head1 ACCESSORS

=head2 id

  data_type: INTEGER
  default_value: undef
  is_auto_increment: 1
  is_nullable: 1
  size: undef

=head2 role

  data_type: TEXT
  default_value: NULL
  is_nullable: 1
  size: undef

=cut

__PACKAGE__->add_columns(
  "id",
  {
    data_type => "INTEGER",
    default_value => undef,
    is_auto_increment => 1,
    is_nullable => 1,
    size => undef,
  },
  "role",
  {
    data_type => "TEXT",
    default_value => \"NULL",
    is_nullable => 1,
    size => undef,
  },
);
__PACKAGE__->set_primary_key("id");

=head1 RELATIONS

=head2 users_to_roles

Type: has_many

Related object: L<Madre::Sync::Schema::Result::UsersToRole>

=cut

__PACKAGE__->has_many(
  "users_to_roles",
  "Madre::Sync::Schema::Result::UsersToRole",
  { "foreign.role" => "self.id" },
);


# Created by DBIx::Class::Schema::Loader v0.05003 @ 2010-07-30 10:25:49
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:xc0RbMJduLNIOo98Svam5A


__PACKAGE__->load_components("InflateColumn::DateTime", "TimeStamp");

# You can replace this text with custom content, and it will be preserved on regeneration
1;
