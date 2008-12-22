
package Padre::Task::SyntaxChecker::Perl6;
use strict;
use warnings;

our $VERSION = '0.21';

use base 'Padre::Task::SyntaxChecker';

use version;

sub run {
    my $self = shift;
    $self->_check_syntax();
    return 1;
}

sub _check_syntax {
    my $self = shift;
    
    my $nlchar = $self->{newlines};
    $self->{text} =~ s/$nlchar/\n/g if defined $nlchar;

    # Since we have the results ready, 
    # and yeah this is kind of dumb
    $self->{syntax_check} = $self->{issues};
}

1;

__END__

=head1 NAME

Padre::Task::SyntaxChecker::Perl6 - Perl document syntax-checking in the background

=head1 SYNOPSIS

  # by default, the text of the current document
  # will be fetched as will the document's notebook page.
  my $task = Padre::Task::SyntaxChecker::Perl6->new(
    newlines => "\r\n", # specify the newline type!
  );
  $task->schedule;
  
  my $task2 = Padre::Task::SyntaxChecker::Perl6->new(
    text => Padre::Documents->current->text_get,
    notebook_page => Padre::Documents->current->editor,
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

Ahmad M. Zawawi C<< <ahmad.zawawi@gmail.com> >>

=head1 COPYRIGHT AND LICENSE

Copyright 2008 Gabor Szabo.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl 5 itself.

=cut

# Copyright 2008 Gabor Szabo.
# LICENSE
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl 5 itself.
