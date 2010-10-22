package Padre::Plugin::Perl6::Syntax;

# ABSTRACT: Perl document background syntax-checker

use 5.010;
use strict;
use warnings;
use Carp         ();
use Params::Util ();
use Padre::Task  ();

our @ISA     = 'Padre::Task';

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

	# Clone issues
	my $cloned_issues = [];
	if($document->{issues}) {
		my @issues = @{$document->{issues}};
		foreach (@issues) {
			my %cloned_issue = %$_;
			push @{$cloned_issues}, \%cloned_issue;
		}
	}
	$self->{issues} = $cloned_issues;

	return $self;
}

sub run {
	my $self = shift;

	$self->{model} = delete $self->{issues};

	return 1;
}

1;

__END__

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
