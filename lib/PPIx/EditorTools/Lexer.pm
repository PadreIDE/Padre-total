package PPIx::EditorTools::Lexer;

# ABSTRACT: Simple Lexer used for syntax highlighting

use 5.008;
use strict;
use warnings;
use Carp;

use base 'PPIx::EditorTools';
use Class::XSAccessor accessors => {};

use PPI;

=pod

=head1 SYNOPSIS

  PPIx::EditorTools::Lexer->new->lexer(
        code => "package TestPackage;\nsub x { 1;\n",
        highlighter => sub {
		my ( $css, $row, $rowchar, $len ) = @_;
                ...
        },
      );

=head1 DESCRIPTION

Go over the various interesting elements of a give piece
of code or an already process PPI tree.
For each token call the user supplied 'highlighter' function with
the follow values:

  $css     - The keyword that can be used for colouring.
  $row     - The row number where the token starts
  $rowchar - The character within that row where the token starts
  $len     - The length of the token

=head1 METHODS

=over 4

=item new()

Constructor. Generally shouldn't be called with any arguments.

=item find( ppi => PPI::Document $ppi, highlighter => sub {...} )
=item find( code => Str $code, highlighter => sub ...{} )

Accepts either a C<PPI::Document> to process or a string containing
the code (which will be converted into a C<PPI::Document>) to process.
Return a reference to an array.

=back

=cut

sub lexer {
	my ( $self, %args ) = @_;
	my $markup = delete $args{highlighter};

	$self->process_doc(%args);

	my $ppi = $self->ppi;

	return [] unless defined $ppi;
	$ppi->index_locations;

	my @tokens = $ppi->tokens;

	foreach my $t (@tokens) {

		my ( $row, $rowchar, $col ) = @{ $t->location };

		my $css = class_to_css($t);

		my $len = $t->length;

		$markup->( $css, $row, $rowchar, $len );
	}
}


sub class_to_css {
	my $Token = shift;

	if ( $Token->isa('PPI::Token::Word') ) {

		# There are some words we can be very confident are
		# being used as keywords
		unless ( $Token->snext_sibling and $Token->snext_sibling->content eq '=>' ) {
			if ( $Token->content =~ /^(?:sub|return)$/ ) {
				return 'keyword';
			} elsif ( $Token->content =~ /^(?:undef|shift|defined|bless)$/ ) {
				return 'core';
			}
		}

		if ( $Token->previous_sibling and $Token->previous_sibling->content eq '->' ) {
			if ( $Token->content =~ /^(?:new)$/ ) {
				return 'core';
			}
		}

		if ( $Token->parent->isa('PPI::Statement::Include') ) {
			if ( $Token->content =~ /^(?:use|no)$/ ) {
				return 'keyword';
			}
			if ( $Token->content eq $Token->parent->pragma ) {
				return 'pragma';
			}
		} elsif ( $Token->parent->isa('PPI::Statement::Variable') ) {
			if ( $Token->content =~ /^(?:my|local|our)$/ ) {
				return 'keyword';
			}
		} elsif ( $Token->parent->isa('PPI::Statement::Compound') ) {
			if ( $Token->content =~ /^(?:if|else|elsif|unless|for|foreach|while|my)$/ ) {
				return 'keyword';
			}
		} elsif ( $Token->parent->isa('PPI::Statement::Package') ) {
			if ( $Token->content eq 'package' ) {
				return 'keyword';
			}
		} elsif ( $Token->parent->isa('PPI::Statement::Scheduled') ) {
			return 'keyword';
		}
	}

	# Normal coloring
	my $css = ref $Token;
	$css =~ s/^.+:://;
	$css;
}


1;

__END__

=head1 SEE ALSO

This class inherits from C<PPIx::EditorTools>.
Also see L<App::EditorTools>, L<Padre>, and L<PPI>.

=cut

# Copyright 2008-2011 The Padre development team as listed in Padre.pm.
# LICENSE
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl 5 itself.

