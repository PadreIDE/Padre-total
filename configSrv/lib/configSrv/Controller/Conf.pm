package configSrv::Controller::Conf;
use Moose;
use namespace::autoclean;

BEGIN {extends 'Catalyst::Controller::REST'; }

use JSON::Any;

=head1 NAME

configSrv::Controller::Conf - Catalyst Controller
I should rewrite this to just use ActionClass('REST'), , to remove the redundant serialization/deserialization


=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut

sub conf
:Chained('/login/required')
:PathPart('user/config')
:ActionClass('REST') { }

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
            $c,
            message => 'Config storage failure.',
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

