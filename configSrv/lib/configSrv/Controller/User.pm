package configSrv::Controller::User;
use Moose;
use namespace::autoclean;

BEGIN {extends 'Catalyst::Controller::REST'; }

=head1 NAME

configSrv::Controller::User - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut


=head2 index

=cut


# we differentiate register and user in the User controller because we need
# to be able to accept POSTs without login
sub register 
:Global 
:ActionClass('REST') { }

sub register_PUT {
   my ($self, $c) = @_;
   my $users_rs = $c->model('padreDB::User');
   my $data = $c->request->data;

   if ($c->user_exists()) { 
      $self->status_bad_request(
         $c, 
         message => "You cannot create multiple accounts." 
      );
   }

   # attempt to create the user
   my $newuser = eval { $users_rs->create({
            username => $data->{username},
            email    => $data->{email},
            password => $data->{password},
         }) };
   if ($@) {
      $c->log->debug( "User signup failure: $@" );

      $self->status_bad_request(
         $c,
         message => "User signup failure",
      );
      return;
   }

  $self->status_ok(
    $c,
    entity => { 0 => 0 }, 
  );

}

*register_POST = *register_PUT;

# handle all LOGGED IN user interaction
sub user 
:Chained('/login/required') 
:PathPart('user') 
:ActionClass('REST') { 
   my ($self, $c) = @_;

   # is this even needed?
   $c->stash(users_rs => $c->model('padreDB::User'));
   $c->stash(roles_rs => $c->model('padreDB::Role'));
}

sub user_GET { 
   my ($self, $c) = @_;
   my $users_rs = $c->stash->{users_rs};

   # Return a 200 OK, with the data in entity
   # serialized in the body
   $self->status_ok(
      $c,
      entity => $c->user,
   );
}

# 
sub user_POST { 
   my ($self, $c) = @_;
   my $data = $c->request->data;
   my $user = $c->user->get_object();

   # update email .. its the only user option we can change
   if (exists $data->{email} && exists $data->{password}) { 
      eval {
         $user->update({
               email    => $data->{email},
               password => $data->{password},
            });
      };
      if ($@) { 
         $c->log->debug( "User modification failure: $@" );
         $self->status_bad_request(
            $c,
            message => "User signup failure",
         );
         return;
      }

      # we've made it through the request ok
      $self->status_ok(
         $c,
         entity => { },
      );
   }
}

*user_PUT = *user_POST;

# delete account
sub user_DELETE { 
   my ($self, $c) = @_;
   $c->user->delete();

   $self->status_ok(
      $c,
      entity => { }, 
   );
}



=head1 AUTHOR

,,,

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;
