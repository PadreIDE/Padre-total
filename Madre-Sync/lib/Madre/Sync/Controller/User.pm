package Madre::Sync::Controller::User;

=pod

=head1 NAME

Madre::Sync::Controller::User - Catalyst Controller

=head1 DESCRIPTION

Provides interface to the user and register resource for the REST webservice.

=head1 METHODS

=cut

use Moose;
use namespace::autoclean;

BEGIN {
	extends 'Catalyst::Controller::REST';
}

=pod

=head2 register 

Global REST actionclass method. Provides private POST and PUT methods for unlogged-in
users. If logged in, registration attempt will fail with a 302 bad request response.

=cut

# We differentiate register and user in the User controller because we need
# to be able to accept POSTs without login
sub register :Global :ActionClass('REST') { }

=pod

=head2 register_PUT

private PUT method for register, provides PUT handling. 

=cut

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
	my $newuser = eval {
		$users_rs->create( {
			username => $data->{username},
			email    => $data->{email},
			password => $data->{password},
		} )
	};
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

=pod

=head2 user

Global REST actionclass method. Provides access to the user resource. Login is required
to interact with this resource through  the /login/required chain. provides POST, PUT 
and DELETE HTTP actions. If not logged in, registration attempt will fail with a 
302 bad request response.

=cut

# Handle all LOGGED IN user interaction
sub user :Chained('/login/required') :PathPart('user') :ActionClass('REST') {
	my ($self, $c) = @_;

	# Is this even needed?
	$c->stash(users_rs => $c->model('padreDB::User'));
	$c->stash(roles_rs => $c->model('padreDB::Role'));
}

=pod

=head2 user_GET 

private GET method for user, provides GET handling. 

=cut

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

=pod

=head2 user_POST

private POST method for user, provides POST handling. 
Synonymous with user PUT.

=cut

sub user_POST { 
	my ($self, $c) = @_;
	my $data = $c->request->data;
	my $user = $c->user->get_object();

	# Update email .. its the only user option we can change
	if (exists $data->{email} && exists $data->{password}) { 
		eval {
			$user->update( {
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

		# We've made it through the request ok
		$self->status_ok(
			$c,
			entity => { },
		);
	}
}

*user_PUT = *user_POST;

=pod

=head2 user_DELETE

private DELETE method for user, provides DELETE handling. 
Synonymous with user PUT.

=cut

# Delete an account
sub user_DELETE { 
	my ($self, $c) = @_;
	$c->user->delete;

	$self->status_ok(
		$c,
		entity => { }, 
	);
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=head1 AUTHOR

,,,

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
