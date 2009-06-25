package PPIx::EditorTools::FindVariableDeclaration;

use strict;
use warnings;
use Carp;

use base 'PPIx::EditorTools';
use Class::XSAccessor accessors => { 'location' => 'location' };

our $VERSION = '0.04';

=pod

=head1 NAME

PPIx::EditorTools::FindVariableDeclaration - Finds where a variable was declared using PPI

=head1 SYNOPSIS

  # finds declaration of variable at cursor
  my $declaration = PPIx::EditorTools::FindVariableDeclaration->new->find(
    code =>
      "package TestPackage;\nuse strict;\nuse warnings;\nmy \$x=1;\n\$x++;"
    line => 5,
    column => 2,
  );
  my $location = $declaration->element->location;

=head1 DESCRIPTION

Finds the location of a variable declaration.

=head1 METHODS

=over 4

=item new()

Constructor. Generally shouldn't be called with any arguments.

=item find( ppi => PPI::Document $ppi, line => $line, column => $column )
=item find( code => Str $code, line => $line, column => $column )

Accepts either a C<PPI::Document> to process or a string containing
the code (which will be converted into a C<PPI::Document>) to process.
Searches for the variable declaration and returns a
C<PPIx::EditorTools::ReturnObject> with the declaration
(C<PPI::Statement::Variable>) available via the C<element> accessor. 

Croaks with a "no token" exception if no token is found at the location.
Croaks with a "no declaration" exception if unable to find the declaration.

=back

=cut

sub find {
    my ( $self, %args ) = @_;
    $self->process_doc(%args);
    my $column = $args{column} or croak "column required";
    my $line   = $args{line}   or croak "line required";
    my $location = [ $line, $column ];

    my $ppi = $self->ppi;
    $ppi->flush_locations;

    my $token = PPIx::EditorTools::find_token_at_location( $ppi, $location );
    croak "no token" unless $token;

    my $declaration = PPIx::EditorTools::find_variable_declaration($token);
    croak "no declaration" unless $declaration;

    return PPIx::EditorTools::ReturnObject->new(
        ppi     => $ppi,
        element => $declaration,
    );
}

1;

__END__

=head1 SEE ALSO

This class inherits from C<PPIx::EditorTools>. 
Also see L<App::EditorTools>, L<Padre>, and L<PPI>.

=head1 AUTHOR

Steffen Mueller C<smueller@cpan.org>
Mark Grimes C<mgrimes@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright 2008-2009 The Padre development team as listed in Padre.pm.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl 5 itself.

=cut

# Copyright 2008-2009 The Padre development team as listed in Padre.pm.
# LICENSE
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl 5 itself.
