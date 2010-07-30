package Madre::Sync;

use 5.008005;
use Moose;
use namespace::autoclean;
use Catalyst::Runtime 5.80;

use Catalyst qw{
	ConfigLoader
	Static::Simple
	+CatalystX::SimpleLogin
	Authentication
	Session
	Session::Store::File
	Session::State::Cookie
	Static::Simple
};

our $VERSION = '0.01';

extends 'Catalyst';
with    'CatalystX::REPL';

# Configure the application.
__PACKAGE__->config(
	name => 'Madre-Sync',

	# Disable deprecated behavior needed by old applications
	disable_component_resolution_regex_fallback => 1,

	'Plugin::Authentication' => {
		default => {
			credential => {
				class          => 'Password',
				password_field => 'password',
				password_type  => 'clear'
			},
			store => { 
				class                     => 'DBIx::Class',
				user_model                => 'padreDB::User',
				role_relation             => 'roles',
				role_field                => 'role',
				use_userdata_from_session => '1'
			},
		},
	},
);

# Start the application
__PACKAGE__->setup;

1;

__END__

=pod

=head1 NAME

Madre::Sync - Catalyst based application

=head1 SYNOPSIS

    script/madre_sync_server.pl

=head1 DESCRIPTION

Server-side component to Madre::Sync - an extension to Padre to allow 
remote sync'ing / storage of Padre user configurations. All interactions
are RESTful.

=head1 DEPLOYMENT 

Follow standard catalyst application deployment procedures for Madre::Sync.
Any database (including SQLite) should suffice for db support.

=head1 SEE ALSO

L<Madre::Sync::Controller::User>,
L<Madre::Sync::Controller::Conf>,
L<Madre::Sync::Controller::Root>,
L<Catalyst>

=head1 AUTHOR

Adam Kennedy E<lt>adamk@cpan.orgE<gt>

Matthew Phillips E<lt>mattp@cpan.orgE<gt>

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
