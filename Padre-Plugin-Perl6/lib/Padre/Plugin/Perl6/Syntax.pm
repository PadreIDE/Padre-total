package Padre::Plugin::Perl6::Syntax;

use strict;
use warnings;
use Padre::Task  ();

our $VERSION = '0.65';
our @ISA     = 'Padre::Task';

######################################################################
# Constructor

sub new {
	my $self = shift->SUPER::new(@_);

	# Just convert the document to text for now.
	# Later, we'll suck in more data from the project and
	# other related documents to do syntax checks more awesomely.
	unless ( Params::Util::_INSTANCE( $self->{document}, 'Padre::Document' ) ) {
		die "Failed to provide a document to the syntax check task";
	}

	# Remove the document entirely as we do this,
	# as it won't be able to survive serialisation.
	my $document = delete $self->{document};
	$self->{issues}     = $document->{issues};
	
	

	return $self;
}

######################################################################
# Padre::Task Methods

sub run {
	my $self = shift;

	# Get the syntax problems list
	my @issues = delete $self->{issues};
	$self->{model} = \@issues;
	use Data::Dumper; print Dumper($self->{model});
	
	return 1;
}

1;

__END__

=head1 NAME

Padre::Plugin::Perl6::Syntax - Perl document syntax-checking in the background

=head1 SYNOPSIS

  require Padre::Plugin::Perl6::Syntax;
  my $task = Padre::Plugin::Perl6::Syntax->new(
	document => $self,
  );
  $task->schedule;
  
=head1 DESCRIPTION

This class implements syntax checking of Perl documents in
the background. It inherits from L<Padre::Task::SyntaxChecker>.
Please read its documentation!

=head1 SEE ALSO

This class inherits from L<Padre::Task> and its instances can be scheduled
using L<Padre::TaskManager>.

The transfer of the objects to and from the worker threads is implemented
with L<Storable>.

=head1 AUTHOR

Ahmad M. Zawawi C<< <ahmad.zawawi at gmail.com> >>

Gabor Szabo L<http://szabgab.com/>

=head1 COPYRIGHT AND LICENSE

Copyright 2008-2009 Padre Developers as in Perl6.pm

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl 5 itself.
