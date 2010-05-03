package Padre::Task2::Eval;

=pod

=head1 NAME

Padre::Task2::Eval - Task for executing arbitrary code via a string eval

=head1 SYNOPSIS

  my $task = Padre::Task2::Eval->new(
      prepare => '1 + 1',
      run     => 'my $foo = sub { 2 + 3 }; $foo->();',
      finish  => '$_[0]->{prepare}',
  );
  
  $task->prepare;
  $task->run;
  $task->finish;

=head1 DESCRIPTION

B<Padre::Task2::Eval> is a stub class used to implement testing and other
miscellaneous functionality.

It takes three named string parameters matching each of the three execution
phases. When each phase of the task is run, the string will be eval'ed and
the result will be stored in the same has key as the source string.

If the key does not exist at all, nothing will be executed for that phase.

Regardless of the execution result (or the non-execution of the phase) each
phase will always return true. However, if the string eval throws an
exception it will escape the task object (although when run properly inside
of a task handle it should be caught by the handle).

=head1 METHODS

This class contains now additional methods beyond the defaults provided by
the L<Padre::Task2> API.

=cut

use 5.008005;
use strict;
use warnings;
use Padre::Task2 ();

our $VERSION = '0.59';
our @ISA     = 'Padre::Task2';

sub prepare {
	if ( exists $_[0]->{prepare} ) {
		$_[0]->{prepare} = eval $_[0]->{prepare};
		die $@ if $@;
	}
	return 1;
}

sub run {
	if ( exists $_[0]->{run} ) {
		$_[0]->{run} = eval $_[0]->{run};
		die $@ if $@;
	}
	return 1;
}

sub finish {
	if ( exists $_[0]->{finish} ) {
		$_[0]->{finish} = eval $_[0]->{finish};
		die $@ if $@;
	}
	return 1;
}

1;

=pod

=head1 COPYRIGHT & LICENSE

Copyright 2008-2010 The Padre development team as listed in Padre.pm.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut

# Copyright 2008-2010 The Padre development team as listed in Padre.pm.
# LICENSE
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl 5 itself.
