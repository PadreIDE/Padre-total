package Padre::Plugin::Perl6::StdColorizer;

# ABSTRACT: Perl 6 Colorizer

use strict;
use warnings;

use Padre::Plugin::Perl6::Colorizer ();
our @ISA = ('Padre::Plugin::Perl6::Colorizer');

sub colorize {
	my $self = shift;
	$Padre::Plugin::Perl6::Colorizer::colorizer = 'STD';
	$self->SUPER::colorize(@_);
}

1;
