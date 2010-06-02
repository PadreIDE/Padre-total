package Padre::Task2::Outline;

use 5.008;
use strict;
use warnings;
use Padre::Task2   ();
use Padre::Current ();

our $VERSION = '0.62';
our @ISA     = 'Padre::Task2';

=pod

=head1 NAME

Padre::Task2::Outline - Generic background processing task to
gather structure info on the current document

=head1 SYNOPSIS

  package Padre::Task2::Outline::MyLanguage;
  
  use base 'Padre::Task2::Outline';
  
  sub run {
          my $self = shift;
          my $doc_text = $self->{text};
          # black magic here
          $self->{outline} = ...;
          return 1;
  };
  
  1;
  
  # elsewhere:
  
  # by default, the text of the current document
  # will be fetched as will the document's notebook page.
  my $task = Padre::Task2::Outline::MyLanguage->new();
  $task->schedule;
  
  my $task2 = Padre::Task2::Outline::MyLanguage->new(
      text   => Padre::Current->document->text_get,
      editor => Padre::Current->editor,
  );
  $task2->schedule;

=head1 DESCRIPTION

This is a base class for all tasks that need to do
expensive structure info gathering in a background task.

You can either let C<Padre::Task2::Outline> fetch the
Perl code for parsing from the current document
or specify it as the "C<text>" parameter to
the constructor.

To create a outline gatherer for a given document type C<Foo>,
you create a subclass C<Padre::Task::Outline::Foo> and
implement the C<run> method which uses the C<$self-E<gt>{text}>
attribute of the task object for its nefarious structure info gathering
purposes and then stores the result in the C<$self-E<gt>{outline}>
attribute of the object. The result should be a data structure of the
form defined in the documentation of the C<Padre::Document::get_outline>
method. See L<Padre::Document>.

This base class requires all logic necessary to update the GUI
with the structure info in a method C<update_gui> of the derived
class. That method is called in the C<finish()> hook.

=cut

sub new {
	my $class = shift;
	my $self  = $class->SUPER::new(@_);
	unless ( defined $self->{text} ) {
		$self->{text} = Padre::Current->document->text_get;
	} # TODO check whether this is necessary

	my %args = @_;
	$self->{filename} = $args{filename};

	return $self;
}

sub run {
	my $self = shift;
	return 1;
}

sub prepare {
	my $self = shift;
	unless ( defined $self->{text} ) {
		require Carp;
		Carp::croak("Could not find the document's text.");
	}
	return 1;
}

sub finish {
	$_[0]->update_gui;
	return;
}

1;

__END__

=pod

=head1 SEE ALSO

This class inherits from C<Padre::Task> and its instances can be scheduled
using C<Padre::TaskManager>.

The transfer of the objects to and from the worker threads is implemented
with L<Storable>.

=head1 AUTHOR

Steffen Mueller E<lt>smueller@cpan.orgE<gt>

Heiko Jansen E<lt>heiko_jansen@web.deE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2008-2010 The Padre development team as listed in Padre.pm.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl 5 itself.

=cut

# Copyright 2008-2010 The Padre development team as listed in Padre.pm.
# LICENSE
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl 5 itself.
