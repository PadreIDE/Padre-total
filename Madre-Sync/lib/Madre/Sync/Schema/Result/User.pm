package Madre::Sync::Schema::Result::User;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

Madre::Sync::Schema::Result::User

=cut

__PACKAGE__->table("users");

=head1 ACCESSORS

=head2 id

  data_type: INTEGER
  default_value: undef
  is_auto_increment: 1
  is_nullable: 0
  size: undef

=head2 username

  data_type: TEXT
  default_value: undef
  is_nullable: 0
  size: undef

=head2 email

  data_type: TEXT
  default_value: undef
  is_nullable: 0
  size: undef

=head2 password

  data_type: TEXT
  default_value: undef
  is_nullable: 0
  size: undef

=cut

__PACKAGE__->add_columns(
  "id",
  {
    data_type => "INTEGER",
    default_value => undef,
    is_auto_increment => 1,
    is_nullable => 0,
    size => undef,
  },
  "username",
  {
    data_type => "TEXT",
    default_value => undef,
    is_nullable => 0,
    size => undef,
  },
  "email",
  {
    data_type => "TEXT",
    default_value => undef,
    is_nullable => 0,
    size => undef,
  },
  "password",
  {
    data_type => "TEXT",
    default_value => undef,
    is_nullable => 0,
    size => undef,
  },
);
__PACKAGE__->set_primary_key("id");
__PACKAGE__->add_unique_constraint("username_unique", ["username"]);
__PACKAGE__->add_unique_constraint("email_unique", ["email"]);

=head1 RELATIONS

=head2 users_to_roles

Type: has_many

Related object: L<Madre::Sync::Schema::Result::UsersToRole>

=cut

__PACKAGE__->has_many(
  "users_to_roles",
  "Madre::Sync::Schema::Result::UsersToRole",
  { "foreign.username" => "self.id" },
);

=head2 config

Type: might_have

Related object: L<Madre::Sync::Schema::Result::Config>

=cut

__PACKAGE__->might_have(
  "config",
  "Madre::Sync::Schema::Result::Config",
  { "foreign.id" => "self.id" },
);


# Created by DBIx::Class::Schema::Loader v0.05003 @ 2010-07-30 10:25:49
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:I65KaB5Bc2VzItyVozYP3A


# You can replace this text with custom content, and it will be preserved on regeneration

use Email::Valid;
__PACKAGE__->load_components("InflateColumn::DateTime", "TimeStamp");

# handle email and user validation 
sub new { 
   my ($class, $args) = @_; 

   if (exists $args->{email}
      && ! Email::Valid->address($args->{email}) ) { 
      die 'Email invalid.';
   }   

   return $class->next::method($args);
}

sub set_column { 
   my ($class, $column, $new_value) = @_; 

   if ($column =~ /email/) {
      if (defined $new_value
         && ! Email::Valid->address($new_value) ) { 
         die 'Email invalid.';
      }   
   }   

   return $class->next::method($column, $new_value);
}

1;
