package Perl6::Refactor;

use warnings;
use strict;

our $VERSION = '0.01';

sub new {
	#XXX-implement
}

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

=head1 NAME

Perl6::Refactor - The great new Perl6::Refactor!

=head1 SYNOPSIS

Perl 6 Refactor includes tools for renaming variables, finding variables 
declarations and more....

Perhaps a little code snippet.

    use Perl6::Refactor;

    my $foo = Perl6::Refactor->new();

=head1 METHODS

=head2 rename_variable

=head2 find_variable_declaration

=head1 AUTHOR

Ahmad M. Zawawi, C<< <ahmad.zawawi at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-perl6-refactor at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Perl6-Refactor>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Perl6::Refactor


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Perl6-Refactor>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Perl6-Refactor>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Perl6-Refactor>

=item * Search CPAN

L<http://search.cpan.org/dist/Perl6-Refactor/>

=back

=head1 COPYRIGHT & LICENSE

Copyright (C) 2009 Ahmad M. Zawawi C<< <ahmad.zawawi at gmail.com> >>

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.