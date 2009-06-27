package Padre::Task::PPI::IntroduceTemporaryVariable;

use strict;
use warnings;
use Padre::Wx ();

our $VERSION = '0.38';

use base 'Padre::Task::PPI';

=pod

=head1 NAME

Padre::Task::PPI::IntroduceTemporaryVariable - Introduces a temporary variable using PPI

=head1 SYNOPSIS

  my $tempvarmaker = Padre::Task::PPI::IntroduceTemporaryVariable->new(
          document       => $document_obj,
          start_location => [$line, $column], # or just character position
          end_location   => [$line, $column], # or ppi-style location
          varname        => '$foo',
  );
  
  $tempvarmaker->schedule();

=head1 DESCRIPTION

Given a region of code within a statement, replaces that code with a temporary variable.
Declares and initializes the temporary variable right above the statement that included the selected
expression.

Usually, you simply set C<start_position> to what C<<$editor->GetSelectionStart()>> returns
and C<end_position> to C<<$editor->GetSelectionEnd() - 1>>.

=cut

sub prepare {
	my $self = shift;
	$self->SUPER::prepare(@_);

	# move the document to the main-thread-only storage
	my $mto = $self->{main_thread_only} ||= {};
	$mto->{document} = $self->{document}
		if defined $self->{document};
	delete $self->{document};
	if ( not defined $mto->{document} ) {
		require Carp;
		Carp::croak("Missing Padre::Document::Perl object as {document} attribute of the temporary-variable task");
	}
        
	foreach my $key (qw(start_location end_location)) {
		if ( not defined $self->{$key} ) {
			require Carp;
			Carp::croak("Need a {$key}!");
		}
		elsif (not ref($self->{$key})) {
			my $doc = $mto->{document};
			$self->{$key} = $doc->character_position_to_ppi_location($self->{$key});
		}
	}

	return ();
}

sub process_ppi {
	my $self     = shift;
	my $ppi      = shift or return;
	my $location = $self->{start_location};

	# TODO: PPI bug? This shouldn't be necessary!
	require Padre::PPI;
	$ppi->flush_locations;
	my $token = Padre::PPI::find_token_at_location( $ppi, $location );
        
	if ( not $token ) {
		$self->{error} = "no token";
		return;
	}

	my $statement = $token->statement();
	if ( not defined $statement ) {
		$self->{error} = "no statement";
		return;
	}
        # walk up the PPI tree until we reach a sort of structure that's not a statement.
        # FIXME: This may or may not be robust. A PPI::Statement claims to be what's
        #        defined as "statements" in perlsyn, but it's not! perlsyn says all statements
        #        end in a semicolon unless at the end of a block.
        #        For PPI, Statements can be part of others and thus don't necessarily have
        #        a semicolon.
        while (1) {
          my $parent = $statement->statement();
          last if not defined $parent;
          if ($parent eq $statement) { # exactly the same object, ie. is a statement already
            $parent = $statement->parent(); # force the parent
            last if not $parent # stop if we're at a block or at the document level
                 or $parent->isa('PPI::Structure::Block')
                 or $parent->isa('PPI::Structure::Document');
            $parent = $parent->statement(); # force it to be a statement
          }
          last if not $parent # stop if the parent isn't a statement
               or not $parent->isa('PPI::Statement');
          $statement = $parent;
        }

	$self->{statement_location} = $statement->location;
	return ();
}

sub finish {
	my $self = shift;
	if ( defined $self->{statement_location} ) {
		my $doc       = $self->{main_thread_only}->{document};
		my $editor    = $doc->editor or return;

		my $state_loc = $self->{statement_location};

		my $state_line       = $state_loc->[0]-1;
		my $state_line_start = $editor->PositionFromLine( $state_line );
		my $state_line_end   = $editor->GetLineEndPosition( $state_line );
		my $state_line_text  = $editor->GetTextRange($state_line_start, $state_line_end);
		my $indent = '';
		$indent = $1 if $state_line_text =~ /^(\s+)/;

		my $start_pos = $doc->ppi_location_to_character_position( $self->{start_location} );
		my $end_pos   = $doc->ppi_location_to_character_position( $self->{end_location} );

		my $varname = $self->{varname};
		$varname = 'tmp' if not defined $varname;
                $varname = '$'.$varname if $varname !~ /^[\$\@\%]/;
                
		my $text = $doc->text_get;
		my $expression = substr($text, $start_pos, $end_pos-$start_pos+1, $varname); # TODO: Pad with spaces?

		my $code = "${indent}my $varname = $expression;\n";
		substr($text, $state_line_start, 0, $code);
		$doc->text_set($text);
		$editor->SetCurrentPos($start_pos);
		$editor->SetSelection( $start_pos, $start_pos );
	} else {
		my $text;
		if ( $self->{error} eq 'no token' ) {
			$text = Wx::gettext("First character of selection does not seem to point at a token.");
		} elsif ( $self->{error} eq 'no statement' ) {
			$text = Wx::gettext("Selection not part of a Perl statement?");
		} else {
			$text = Wx::gettext("Unknown error");
		}
		Wx::MessageBox(
			$text,
			Wx::gettext("Replace Operation Canceled"),
			Wx::wxOK,
			Padre->ide->wx->main
		);
	}
	return ();
}

1;

__END__

=head1 SEE ALSO

This class inherits from C<Padre::Task::PPI>.

=head1 AUTHOR

Steffen Mueller C<smueller@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright 2008-2009 The Padre development team as listed in Padre.pm.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl 5 itself.

=cut

# Copyright 2008-2009 The Padre development team as listed in Padre.pm.
# LICENSE
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl 5 itself.
