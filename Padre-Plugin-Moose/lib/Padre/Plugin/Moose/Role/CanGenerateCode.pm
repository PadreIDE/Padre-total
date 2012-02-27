package Padre::Plugin::Moose::Role::CanGenerateCode;

use Moose::Role;
use Moose::Util::TypeConstraints;
use namespace::clean;

our $VERSION = '0.13';

enum 'GeneratedCodeType', [qw(Moose Mouse MooseX::Declare)];

has 'code_type' => (is => 'rw', isa => 'GeneratedCodeType', default => 'Moose');

sub generate_code {
	my $self = shift;
	my $code_type = shift;

	$self->code_type($code_type);
	return $self->generate_moose_code if $code_type eq 'Moose';
	return $self->generate_mouse_code if $code_type eq 'Mouse';
	return $self->generate_moosex_declare_code if $code_type eq 'MooseX::Declare';
	die "Unsupported code_type: '" . $code_type . "'\n";
}

requires 'generate_moose_code';
requires 'generate_mouse_code';
requires 'generate_moosex_declare_code';

1;

__END__

=pod

=head1 NAME

Padre::Plugin::Moose::Role::CanGenerateCode - Something that can generate Moose, Mouse or MooseX::Declare code

=cut
