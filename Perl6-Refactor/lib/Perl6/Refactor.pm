package Perl6::Refactor;

use Moose;

# ABSTRACT: Refactors Perl 6 code

sub rename_variable {
	my $self = shift;

	#XXX-implement
}

sub find_variable_declaration {
	my $self = shift;

	#XXX-implement
}

# -------------- End of Perl6::Refactor ----------------
1;

__END__

=head1 SYNOPSIS

Perl 6 Refactor includes tools for renaming variables, finding variables
declarations and more....

Perhaps a little code snippet.

    use Perl6::Refactor;

    my $foo = Perl6::Refactor->new();
