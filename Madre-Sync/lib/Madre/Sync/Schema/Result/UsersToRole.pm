package Madre::Sync::Schema::Result::UsersToRole;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

Madre::Sync::Schema::Result::UsersToRole

=cut

__PACKAGE__->table("users_to_roles");

=head1 ACCESSORS

=head2 username

  data_type: INTEGER
  default_value: undef
  is_foreign_key: 1
  is_nullable: 0
  size: undef

=head2 role

  data_type: INTEGER
  default_value: undef
  is_foreign_key: 1
  is_nullable: 0
  size: undef

=cut

__PACKAGE__->add_columns(
  "username",
  {
    data_type => "INTEGER",
    default_value => undef,
    is_foreign_key => 1,
    is_nullable => 0,
    size => undef,
  },
  "role",
  {
    data_type => "INTEGER",
    default_value => undef,
    is_foreign_key => 1,
    is_nullable => 0,
    size => undef,
  },
);
__PACKAGE__->set_primary_key("username", "role");

=head1 RELATIONS

=head2 username

Type: belongs_to

Related object: L<Madre::Sync::Schema::Result::User>

=cut

__PACKAGE__->belongs_to(
  "username",
  "Madre::Sync::Schema::Result::User",
  { id => "username" },
  {},
);

=head2 role

Type: belongs_to

Related object: L<Madre::Sync::Schema::Result::Role>

=cut

__PACKAGE__->belongs_to(
  "role",
  "Madre::Sync::Schema::Result::Role",
  { id => "role" },
  {},
);


# Created by DBIx::Class::Schema::Loader v0.05003 @ 2010-07-30 10:25:49
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:eCnOpRa0OKS7oriPaZBbCQ


# You can replace this text with custom content, and it will be preserved on regeneration
1;
