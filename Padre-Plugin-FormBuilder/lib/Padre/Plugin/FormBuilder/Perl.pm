package Padre::Plugin::FormBuilder::Perl;

=pod

=head1 NAME

Padre::Plugin::FormBuilder::Perl - wxFormBuilder to Padre dialog code generator

=head1 SYNOPSIS

  my $generator = Padre::Plugin::FormBuilder::Perl->new(
      dialog => $fbp_object->dialog('MyDialog')
  );

=head1 DESCRIPTION

This is a L<Padre>-specific variant of L<FBP::Perl>.

It overloads various methods to make things work in a more Padre-specific way.

=cut

use 5.008005;
use strict;
use warnings;
use Mouse 0.61;

our $VERSION = '0.02';

extends 'FBP::Perl';





######################################################################
# Dialog Generators

sub dialog_isa {
	my $self   = shift;
	my $dialog = shift;
	return [
		"our \@ISA     = qw{",
		"\tPadre::Wx::Role::Main",
		"\tWx::Dialog",
		"};",
	];
}

sub use_wx {
	my $self    = shift;
	my $dialog  = shift;
	return [
		"use Padre::Wx             ();",
		"use Padre::Wx::Role::Main ();",
	];
}

1;

=pod

=head1 SUPPORT

Bugs should be reported via the CPAN bug tracker at

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Padre-Plugin-FormBuilder>

For other issues, or commercial enhancement or support, contact the author.

=head1 AUTHOR

Adam Kennedy E<lt>adamk@cpan.orgE<gt>

=head1 SEE ALSO

L<Padre>

=head1 COPYRIGHT

Copyright 2010 Adam Kennedy.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
