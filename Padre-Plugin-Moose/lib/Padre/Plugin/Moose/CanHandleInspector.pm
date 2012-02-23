package Padre::Plugin::Moose::CanHandleInspector;

use Moose::Role;
use namespace::clean;

our $VERSION = '0.08';

requires 'read_from_inspector';
requires 'write_to_inspector';

1;

__END__

=pod

=head1 NAME

Padre::Plugin::Moose::CanHandleInspector - Something that can read from and write to the object inspector

=cut
