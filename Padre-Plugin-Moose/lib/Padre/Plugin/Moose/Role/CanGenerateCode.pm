package Padre::Plugin::Moose::Role::CanGenerateCode;

use Moose::Role;
use namespace::clean;

our $VERSION = '0.14';

sub generate_code {
	my $self             = shift;
	my $code_gen_options = shift;
	my $code_type        = $code_gen_options->{code_type};

	return $self->generate_moose_code($code_gen_options)          if $code_type eq 'Moose';
	return $self->generate_mouse_code($code_gen_options)          if $code_type eq 'Mouse';
	return $self->generate_moosex_declare_code($code_gen_options) if $code_type eq 'MooseX::Declare';
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
