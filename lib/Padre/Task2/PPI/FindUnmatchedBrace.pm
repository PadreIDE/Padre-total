package Padre::Task2::PPI::FindUnmatchedBrace;

use 5.008;
use strict;
use warnings;
use Padre::Task2::PPI ();
use Padre::Logger;

our $VERSION = '0.62';
our @ISA     = 'Padre::Task2::PPI';

=pod

=head1 NAME

Padre::Task::PPI::FindUnmatchedBrace - C<PPI> based unmatched brace finder

=head1 SYNOPSIS

  my $bracefinder = Padre::Task::PPI::FindUnmatchedBrace->new(
          document => $padre_document,
  );

  $bracefinder->schedule;

=head1 DESCRIPTION

Finds the location of unmatched braces in a C<Padre::Document::Perl>.
If there is no unmatched brace, a message box tells the user about
that glorious fact. If there is one, the cursor will jump to it.

=cut

sub process {
	TRACE('process') if DEBUG;
	my $self  = shift;
	my $ppi   = shift or return;
	my $brace = eval {
		require PPIx::EditorTools::FindUnmatchedBrace;
		PPIx::EditorTools::FindUnmatchedBrace->new->find( ppi => $ppi );
	};
	if ( $@ ) {
		$self->{error} = $@;
		return;
	}

	# An undef brace throws a die here.
	# undef = no error found.
	if ( defined $brace ) {
		# Remember for gui update
		$self->{location} = $brace->element->location;
	}

	return;
}

1;

__END__

=pod

=head1 SEE ALSO

This class inherits from C<Padre::Task::PPI>.

=head1 AUTHOR

Steffen Mueller C<smueller@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright 2008-2010 The Padre development team as listed in Padre.pm.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl 5 itself.

=cut

# Copyright 2008-2010 The Padre development team as listed in Padre.pm.
# LICENSE
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl 5 itself.
