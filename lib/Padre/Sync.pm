package Padre::Sync;

=pod

=head1 NAME

Padre::Sync - Utility functions for handling remote Configuration Syncing

=head1 DESCRIPTION

The C<Padre::Sync> class contains logic for communicating with a remote 
L<Madre::Sync> server. This class interacts with the L<Padre::Wx::Dialog::Sync>
class for user interface display.

=head1 METHODS

=cut

use 5.008;
use strict;
use warnings;
use Carp           ();
use File::Spec     ();
use Scalar::Util   ();
use Params::Util   ();
use JSON::XS       ();
use LWP::UserAgent ();
use HTTP::Cookies  ();
use HTTP::Request::Common qw/GET POST DELETE/;
use Padre::Util     ();
use Padre::Current  ();
use Padre::Constant ();

our $VERSION = '0.84';





#####################################################################
# Constructor and Accessors

=pod

=head2 C<new>

The constructor returns a new C<Padre::Sync> object, but
you should normally access it via the main Padre object:

  my $manager = Padre->ide->config_sync;

First argument should be a Padre object.

=cut

sub new {
	my $class = shift;
	my $ide = Params::Util::_INSTANCE( shift, 'Padre' );
	unless ($ide) {
		Carp::croak("Creation of a Padre::Sync without a Padre not possible");
	}

	# Create the useragent.
	# We need this to handle login actions.
	# Save cookies for state management from Padre session to session
	# is this even wanted? remove at padre close?
	my $ua = LWP::UserAgent->new;
	push @{ $ua->requests_redirectable }, 'POST';
	$ua->timeout(2);
	$ua->cookie_jar(
		HTTP::Cookies->new(
			file => File::Spec->catfile(
				Padre::Constant::CONFIG_DIR,
				'lwp_cookies.dat',
			),
			autosave => 1,
		)
	);

	my $self = bless {
		ide   => $ide,
		state => 'not_logged_in',
		ua    => $ua,
		json  => JSON::XS->new,
		@_,
	}, $class;

	return $self;
}

=pod

=head2 C<main>

A convenience method to get to the main window.

=cut

sub main {
	$_[0]->{ide}->wx->main;
}

=pod

=head2 C<config>

A convenience method to get to the config object

=cut

sub config {
	$_[0]->{ide}->config;
}

=pod

=head2 C<ua> 

A convenience method to get to the useragent object

=cut 

sub ua {
	$_[0]->{ua};
}

=pod

=head2 C<register>

Attempts to register a user account with the information provided on the
Sync server. 
Parameters: a list of key value pairs to be interpreted as POST parameters
Returns error string if user state is already logged in or serverside error occurs.

=cut

sub register {
	my $self   = shift;
	my $params = shift;
	my $server = $self->config->config_sync_server;

	return 'Registration Failure'      unless %$params;
	return 'Failure: no server found.' unless $server;

	if ( $self->{state} ne 'not_logged_in' ) {
		return 'Failure: cannot register account, user already logged in.';
	}

	# this crashes if server is unavailable. FIXME
	my $resp = $self->ua->request(
		POST "$server/register",
		'Content-Type' => 'application/json',
		'Content'      => $self->{json}->encode($params),
	);
	if ( $resp->code == 200 ) {
		return 'Account registered successfully. Please log in.';
	}

	my $h = $self->{json}->decode( $resp->content );

	return "Registration Failure: $h->{error}" if $h->{error};
	return "Registration failure.";
}

=pod

=head2 C<login>

Will log in to remote Sync server using given credentials. State will 
be updated if login successful.

=cut

sub login {
	my $self   = shift;
	my $params = [@_];
	my $server = $self->config->config_sync_server;

	return 'Failure: no server found.' unless $server;

	if ( $self->{state} ne 'not_logged_in' ) {
		return 'Failure: cannot log in, user already logged in.';
	}

	my $resp = $self->ua->request( POST "$server/login", $params );

	if ( $resp->content !~ /Wrong username or password/i and $resp->code == 200 ) {
		$self->{state} = 'logged_in';
		return 'Logged in successfully.';
	}

	return 'Login Failure.';
}

=pod

=head2 C<logout>

If currently logged in, will log the Sync session out from the server.
State will be updated.

=cut

sub logout {
	my $self   = shift;
	my $server = $self->config->config_sync_server;

	return 'Failure: no server found.' if not $server;

	if ( $self->{state} ne 'logged_in' ) {
		return 'Failure: cannot logout, user not logged in.';
	}

	my $resp = $self->ua->request( GET "$server/logout" );

	if ( $resp->code == 200 ) {
		$self->{state} = 'not_logged_in';
		return 'Logged out successfully.';
	}

	return 'Failed to log out.';
}

=pod

=head2 C<server_delete>

Given a logged in session, will attempt to delete the config currently stored
on the Sync server (if one currently exists).
Will fail if not logged in.

=cut

sub server_delete {
	my $self   = shift;
	my $server = $self->config->config_sync_server;

	return 'Failure: no server found.' if not $server;

	if ( $self->{state} ne 'logged_in' ) {
		return 'Failure: user not logged in.';
	}

	my $resp = $self->ua->request( DELETE "$server/user/config" );

	if ( $resp->code == 200 ) {
		return 'Configuration deleted successfully.';
	}

	return 'Failed to delete serverside configuration file.';

}

=pod

=head2 C<local_to_server>

Given a logged in session, will attempt to place the current local config to 
the Sync server. 

=cut

sub local_to_server {
	my $self   = shift;
	my $server = $self->config->config_sync_server;

	return 'Failure: no server found.' if not $server;

	if ( $self->{state} ne 'logged_in' ) {
		return 'Failure: user not logged in.';
	}

	my $conf = $self->config->human;

	# theres gotta be a better way to do this
	my %h;
	for my $k ( keys %$conf ) {
		$h{$k} = $conf->{$k};
	}

	my $resp = $self->ua->request(
		POST "$server/user/config",
		'Content-Type' => 'application/json',
		'Content'      => $self->{json}->encode( \%h ),
	);
	if ( $resp->code == 200 ) {
		return 'Configuration uploaded successfully.';
	}

	return 'Failed to upload configuration file to server.';
}

=pod

=head2 C<server_to_local>

Given a logged in session, will replace the local config with what is stored on 
the server. 
TODO: is validation of config before replacement required?

=cut

sub server_to_local {
	my $self   = shift;
	my $config = $self->config;
	my $server = $config->config_sync_server;

	return 'Failure: no server found.' if not $server;

	if ( $self->{state} ne 'logged_in' ) {
		return 'Failure: user not logged in.';
	}

	my $resp = $self->ua->request( GET "$server/user/config", 'Accept' => 'application/json' );

	my $c;
	eval { $c = $self->{json}->decode( $resp->content ); };
	if ($@) {
		return 'Failed to deserialize serverside configuration.';
	}

	# apply each setting to the global config. should only be HUMAN settings
	delete $c->{Version};
	delete $c->{version};
	for my $key ( keys %$c ) {
		$config->apply( $key, $c->{$key} );
	}
	$config->apply( main_singleinstance => 1 );
	$config->write;

	if ( $resp->code == 200 ) {
		return 'Configuration downloaded and applied successfully.';
	}

	return 'Failed to download serverside configuration file to local Padre instance.';
}

=pod

=head2 C<english_status>

Will return a string explaining current state of Sync
dependent on $self->{state}

=cut

sub english_status {
	my $self = shift;
	return 'User is not currently logged into the system.' if $self->{state} eq 'not_logged_in';
	return 'User is currently logged into the system.'     if $self->{state} eq 'logged_in';
	return "State unknown: $self->{state}";
}

1;

=pod

=head1 SEE ALSO

L<Padre>, L<Padre::Config>

=head1 COPYRIGHT & LICENSE

Copyright 2008-2011 The Padre development team as listed in Padre.pm.

This program is free software; you can redistribute it and/or modify it under the
same terms as Perl 5 itself.

=cut

# Copyright 2008-2011 The Padre development team as listed in Padre.pm.
# LICENSE
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl 5 itself.
