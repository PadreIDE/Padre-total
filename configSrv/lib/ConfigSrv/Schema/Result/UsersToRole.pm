package ConfigSrv::Schema::Result::UsersToRole;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->load_components("InflateColumn::DateTime", "TimeStamp");

=head1 NAME

ConfigSrv::Schema::Result::UsersToRole

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

Related object: L<ConfigSrv::Schema::Result::User>

=cut

__PACKAGE__->belongs_to(
  "username",
  "ConfigSrv::Schema::Result::User",
  { id => "username" },
  {},
);

=head2 role

Type: belongs_to

Related object: L<ConfigSrv::Schema::Result::Role>

=cut

__PACKAGE__->belongs_to("role", "ConfigSrv::Schema::Result::Role", { id => "role" }, {});


# Created by DBIx::Class::Schema::Loader v0.05003 @ 2010-02-27 15:49:19
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:F5Ww+fHJQ7Y3MgvzpzZw2Q


# You can replace this text with custom content, and it will be preserved on regeneration
1;
