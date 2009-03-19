package Padre::Task::ClassSniff;

use strict;
use warnings;
use Padre::Task::PPI ();
use Padre::Wx   ();
use Scalar::Util qw(blessed);

our $VERSION = '0.29';
use base 'Padre::Task::PPI';

=pod

=head1 NAME

Padre::Task::ClassSniff - Running class sniff in the background

=head1 SYNOPSIS

  my $task = Padre::Task::ClassSniff->new(
    mode => 'print_report',
    sniff_config => { ... },
  );
  $task->schedule;

=head1 DESCRIPTION

Runs Class::Sniff on the first namespace of the current document
and prints the results to the Padre output window.

=cut

sub process_ppi {
	my $self = shift;
	my $ppi = shift or return();
	my $mode = $self->{mode} || 'print_report';
	
	
	my $sniff_config = $self->{sniff_config} ||= {};
	
	if (not defined $sniff_config->{class}) {
		$sniff_config->{class} = $self->find_document_namespace($ppi);
	}
	
	if ($mode eq 'print_report') {
		$self->print_report();
	}
	
	return();
}

sub find_document_namespace {
	my $self = shift;
	my $ppi = shift;
	my $ns = $ppi->find_first( 'PPI::Statement::Package' );
	return()
	  if not defined $ns or !blessed($ns) or !$ns->isa('PPI::Statement::Package');
	return $ns->namespace;
}

sub print_report {
	my $self = shift;
	my $sniff_config = $self->{sniff_config};
	
	if (not defined $sniff_config->{class}) {
		$self->task_warn("Could not determine class to run Sniff on.\n");
		return();
	}

	my $sniff = eval {
		Class::Sniff->new($sniff_config);
	};
	
	if (not defined $sniff or $@) {
		$self->task_warn( "Could not create Class::Sniff object" . ($@ ? " ($@)\n" : "\n") );
		return();
	}
	
	my $report = $sniff->report();
	if (defined $report and $report =~ /\S/) {
		$self->task_print( $report . "\n" );
	}
	else {
		$self->task_print( "No bad smell from class '" . $sniff_config->{class} . "'" );
	}
	return();

}

1;

__END__

=head1 SEE ALSO

This class inherits from C<Padre::Task::WithOutput> and its instances can be scheduled
using C<Padre::TaskManager>.

The transfer of the objects to and from the worker threads is implemented
with L<Storable>.

=head1 AUTHOR

Steffen Mueller C<< <smueller@cpan.org> >>

=head1 COPYRIGHT AND LICENSE

Copyright 2008-2009 The Padre development team as listed in Padre.pm.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl 5 itself.

=cut


# Copyright 2008-2009 The Padre development team as listed in Padre.pm.
# LICENSE
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl 5 itself.
