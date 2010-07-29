package Madre::Sync::Controller::Root;

=pod

=head1 NAME

Madre::Sync::Controller::Root - Root Controller for Madre::Sync

=head1 DESCRIPTION

Madre::Sync is a Catalyst webservice designed to handle requests
passed in by a remote Padre::ConfigSync instance. It provides 
a user registration / login mechanism as well as configuration
storage / retrieval / deletion. 

=head1 METHODS

=cut

use Moose;
use namespace::autoclean;

BEGIN {
	extends 'Catalyst::Controller::ActionRole';
}

#
# Sets the actions in this controller to be registered with no prefix
# so they function identically to actions created in MyApp.pm
#
__PACKAGE__->config( namespace => '' );

=pod

=head2 index

The root page (/)
TODO: get rid of this 

=cut

sub index :Path :Args(0) {
	my ( $self, $c ) = @_;

	# Hello World
	$c->response->body( $c->welcome_message );
}

=pod

=head2 default

Standard 404 error page

=cut

sub default :Path {
	my ( $self, $c ) = @_;
	$c->response->body( 'Page not found' );
	$c->response->status(404);
}

=pod

=head2 end

Attempt to render a view, if needed.

=cut

sub end :ActionClass('RenderView') { }

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
