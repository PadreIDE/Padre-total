package Padre::Plugin::Moose::CodeGen;

use Moose::Role;
use namespace::clean;

our $VERSION = '0.06';

requires 'to_code';

1;

__END__

=pod

=head1 NAME

Padre::Plugin::Moose::CodeGen - Something that can generate code

=head1 REQUIRED METHODS

L<to_code>

=cut
