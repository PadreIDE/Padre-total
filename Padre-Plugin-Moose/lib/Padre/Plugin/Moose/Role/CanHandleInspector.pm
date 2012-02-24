package Padre::Plugin::Moose::Role::CanHandleInspector;

use Moose::Role;
use namespace::clean;

our $VERSION = '0.11';

requires 'read_from_inspector';
requires 'write_to_inspector';
requires 'get_grid_data';

1;

__END__

=pod

=head1 NAME

Padre::Plugin::Moose::Role::CanHandleInspector - Something that can read from and write to the object inspector

=cut
