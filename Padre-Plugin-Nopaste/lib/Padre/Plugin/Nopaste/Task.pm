package Padre::Plugin::Nopaste::Task;

use 5.008;
use strict;
use warnings;
use Padre::Task ();
use Padre::Logger;

our $VERSION = '0.3.1';
our @ISA     = 'Padre::Task';

=pod

=head1 NAME

Padre::Plugin::Nopaste::Task - Padre::Task subclass doing nopaste job

=head1 SYNOPSIS


=head1 DESCRIPTION

Async thread that does real nopaste

=cut

sub prepare {
    my ($self) = @_;

    my $main     = $self->{document}->main;
    my $current  = $main->current;
    my $editor   = $current->editor;
    return unless $editor;

    # no selection means send current file
    $self->{text} = $editor->GetSelectedText || $editor->GetText;
}

sub run {
	my $self = shift;

	$self->process();

	return 1;
}

sub process {
    my ($self) = @_;

    require App::Nopaste;
    my $url = App::Nopaste::nopaste($self->{text});

    # show result in output section
    if ( defined $url ) {
        my $text = "Text successfully nopasted at: $url\n";
        $self->{err}=0;
        $self->{message}=$text;
    } else {
        my $text = "Error while nopasting text\n";
        $self->{err}=1;
        $self->{message}=$text;
    }
    return;
}

1;

__END__

=pod

=head1 Standard Padre::Task API

In order not to freeze Padre during web access, nopasting is done in a thread,
as implemented by C<Padre::Task>. Refer to this module's documentation for more
information.

The following methods are implemented:

=over 4

=item * prepare()

=item * process()

=item * run()

=back

=head1 AUTHOR

Alexandr Ciornii, Jerome Quelin, C<< <jquelin@cpan.org> >>

=head1 COPYRIGHT AND LICENSE

Copyright 2008-2010 The Padre development team as listed in Padre.pm.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl 5 itself.

=cut

# Copyright 2008-2010 The Padre development team as listed in Padre.pm.
# LICENSE
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl 5 itself.
