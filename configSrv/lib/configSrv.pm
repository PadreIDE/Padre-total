package configSrv;
use Moose;
use namespace::autoclean;

use Catalyst::Runtime 5.80;

# Set flags and add plugins for the application
#
#         -Debug: activates the debug mode for very useful log messages
#   ConfigLoader: will load the configuration from a Config::General file in the
#                 application's home directory
# Static::Simple: will serve static files from the application's root
#                 directory

use Catalyst qw/
    -Debug
    ConfigLoader
    Static::Simple
    +CatalystX::SimpleLogin
    Authentication
    Session
    Session::Store::File
    Session::State::Cookie
    Static::Simple
/;

extends 'Catalyst';
with 'CatalystX::REPL';


our $VERSION = '0.01';
$VERSION = eval $VERSION;

# Configure the application.
#
# Note that settings in configsrv.conf (or other external
# configuration file that you set up manually) take precedence
# over this when using ConfigLoader. Thus configuration
# details given here can function as a default configuration,
# with an external configuration file acting as an override for
# local deployment.

__PACKAGE__->config(
   name => 'configSrv',
   #'default'   => 'text/x-yaml',
   #'stash_key' => 'rest',

   # Disable deprecated behavior needed by old applications
   disable_component_resolution_regex_fallback => 1,
   'Plugin::Authentication' => {
      default => {
         credential => {
            class => 'Password',
            password_field => 'password',
            password_type => 'clear'
         },
         store => { 
            class => 'DBIx::Class',
            user_model => 'padreDB::User',
            role_relation => 'roles',
            role_field => 'role',
            use_userdata_from_session => '1'
         },
      },
   },
);
# Start the application
__PACKAGE__->setup();


=head1 NAME

configSrv - Catalyst based application

=head1 SYNOPSIS

    script/configsrv_server.pl

=head1 DESCRIPTION

[enter your description here]

=head1 SEE ALSO

L<configSrv::Controller::Root>, L<Catalyst>

=head1 AUTHOR

,,,

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
