package Madre::Sync::Schema::Result::Config;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

Madre::Sync::Schema::Result::Config

=cut

__PACKAGE__->table("configs");

=head1 ACCESSORS

=head2 id

  data_type: INTEGER
  default_value: undef
  is_foreign_key: 1
  is_nullable: 0
  size: undef

=head2 config

  data_type: TEXT
  default_value: undef
  is_nullable: 0
  size: undef

=head2 added

  data_type: DATETIME
  default_value: undef
  is_nullable: 0
  size: undef

=cut

__PACKAGE__->add_columns(
  "id",
  {
    data_type => "INTEGER",
    default_value => undef,
    is_foreign_key => 1,
    is_nullable => 0,
    size => undef,
  },
  "config",
  {
    data_type => "TEXT",
    default_value => undef,
    is_nullable => 0,
    size => undef,
  },
  "added",
  {
    data_type => "DATETIME",
    default_value => undef,
    is_nullable => 0,
    size => undef,
  },
);
__PACKAGE__->set_primary_key("id");
__PACKAGE__->add_unique_constraint("config_unique", ["config"]);

=head1 RELATIONS

=head2 id

Type: belongs_to

Related object: L<Madre::Sync::Schema::Result::User>

=cut

__PACKAGE__->belongs_to("id", "Madre::Sync::Schema::Result::User", { id => "id" }, {});


# Created by DBIx::Class::Schema::Loader v0.05003 @ 2010-07-30 10:25:49
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:553ImSxAFL237vHf5misCA


# You can replace this text with custom content, and it will be preserved on regeneration

__PACKAGE__->load_components("InflateColumn::DateTime", "TimeStamp");

__PACKAGE__->add_columns('added',
   { %{__PACKAGE__->column_info('added') },
      set_on_create => 1,
      set_on_update => 1
   }); 

1;
