package Padre::Plugin::Perl6::Perl6StdColorizer;

use strict;
use warnings;

our $VERSION = '0.59';

use Padre::Plugin::Perl6::Perl6Colorizer;
our @ISA = ('Padre::Plugin::Perl6::Perl6Colorizer');

sub colorize {
	my $self = shift;
	$Padre::Plugin::Perl6::Perl6Colorizer::colorizer = 'STD';
	$self->SUPER::colorize(@_);
}

1;

__END__

=head1 AUTHOR

Ahmad M. Zawawi C<< <ahmad.zawawi at gmail.com> >>

Gabor Szabo L<http://szabgab.com/>

=head1 COPYRIGHT AND LICENSE

Copyright 2008-2009 Padre Developers as in Perl6.pm

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl 5 itself.
