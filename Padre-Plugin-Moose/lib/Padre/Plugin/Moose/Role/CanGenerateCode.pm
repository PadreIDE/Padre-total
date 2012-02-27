package Padre::Plugin::Moose::Role::CanGenerateCode;

use Moose::Role;
use namespace::clean;

our $VERSION = '0.13';

requires 'generate_moose_code';
requires 'generate_mouse_code';
requires 'generate_moosex_declare_code';

1;

__END__

=pod

=head1 NAME

Padre::Plugin::Moose::Role::CanGenerateCode - Something that can generate code

=cut
