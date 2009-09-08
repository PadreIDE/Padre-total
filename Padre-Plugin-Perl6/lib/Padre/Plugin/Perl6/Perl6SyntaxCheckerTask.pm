
package Padre::Plugin::Perl6::Perl6SyntaxCheckerTask;
use strict;
use warnings;

our $VERSION = '0.59';

use base 'Padre::Task::SyntaxChecker';

sub run {
	my $self = shift;

	my $nlchar = $self->{newlines};
	$self->{text} =~ s/$nlchar/\n/g if defined $nlchar;

	# Since we have the results ready,
	# and yeah this is kind of dumb
	$self->{syntax_check} = $self->{issues};

	return 1;
}

1;

__END__

=head1 NAME

Padre::Plugin::Perl6::Perl6SyntaxChecker - Perl document syntax-checking in the background

=head1 SYNOPSIS

  # by default, the text of the current document
  # will be fetched as will the document's notebook page.
  my $task = Padre::Plugin::Perl6::Perl6SyntaxChecker->new(
	newlines => "\r\n", # specify the newline type!
  );
  $task->schedule;
  
  my $task2 = Padre::Plugin::Perl6::Perl6SyntaxChecker->new(
	text => Padre::Current->document->text_get,
	notebook_page => Padre::Current->document->editor,
	on_finish => sub { my $task = shift; ... },
	newlines => "\r\n", # specify the newline type!
  );
  $task2->schedule;

=head1 DESCRIPTION

This class implements syntax checking of Perl documents in
the background. It inherits from L<Padre::Task::SyntaxChecker>.
Please read its documentation!

=head1 SEE ALSO

This class inherits from L<Padre::Task::SyntaxChecker> which
in turn is a L<Padre::Task> and its instances can be scheduled
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
