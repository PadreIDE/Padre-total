package Madre::Sync::Controller::Conf;

use Moose;
use namespace::autoclean;

BEGIN {
	extends 'Catalyst::Controller::REST';
}

use JSON::Any;

=pod

=head1 NAME

Madre::Sync::Controller::Conf - Catalyst Controller

=head1 DESCRIPTION

Provides interface to the conf/config resource for the REST webservice.
TODO: I should rewrite this to just use ActionClass('REST'), , to remove the redundant serialization/deserialization

=head1 METHODS

=cut

=head2 conf 

Global REST actionclass method. Provides private POST and PUT methods for logged-in
users.  If not logged in, registration attempt will fail with a 302 bad request response.

=cut

sub conf
:Chained('/login/required')
:PathPart('user/config')
:ActionClass('REST') { }

=head2 conf_GET 

private GET method for conf, provides GET handling. If logged in, tries to retrieve 
the user config currently stored in the database. If it exists, returns a serialized 
version of it.

=cut

sub conf_GET {
   my ($self, $c) = @_;

   my $configs_rs = $c->model('padreDB::Config');
   my $config = $configs_rs->search({ id => $c->user->id })->single->config;
   $config ||= { 1 => 1 };

   $self->status_ok(
      $c,
      entity => JSON::Any->jsonToObj($config),
   );
}

=head2 conf_PUT 

private PUT method for conf, provides PUT handling. If the given perl data structure
passed in through the request validates, will store it serialized in the database. 
If this fails, will return 302 bad request.

=cut

sub conf_PUT {
   my ($self, $c) = @_;
   my $data = $c->request->data; 

   if ($data) { 
      eval {
         $c->model('padreDB::Config')->update_or_create({
               id => $c->user->id,
               config => JSON::Any->objToJson($data),
            })
      };
      if ($@) { 
         $c->log->debug("Config storage failure: $@");
         $self->status_bad_request(
            $c, message => 'Config storage failure.',
         );
         return;
      }
      $self->status_ok(
         $c,
         entity => { 1 => 1 },
      );
   }
}

*conf_POST = *conf_PUT;



=head2 conf_DELETE

private DELETE method for conf, provides DELETE handling. 
Will always return 200 stats ok, whether or not a config 
was successfully deleted or not. 
TODO: add specific logic for returning 302 bad request when 
a config doesn't exist in the database but a delete is 
attempted anyways? 

=cut

sub conf_DELETE { 
   my ($self, $c) = @_;

   $c->model('padreDB::Config')->search({ id => $c->user->id })->delete;
   
   $self->status_ok(
      $c,
      entity => { 1 => 1 },
   );
}


=head1 AUTHOR

,,,
=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

