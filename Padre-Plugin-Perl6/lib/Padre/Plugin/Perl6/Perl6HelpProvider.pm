package Padre::Plugin::Perl6::PerlHelpProvider;

use strict;
use warnings;

# For Perl 6 documentation support
use App::Grok     ();

our $VERSION = '0.43';
our @ISA     = 'Padre::HelpProvider';

#
# Initialize help
#
sub help_init {
	my $self = shift;

	my @index = ();

	# Return a unique sorted index
	my %seen = ();
	my @unique_sorted_index = sort grep { !$seen{$_}++ } @index;
	$self->{help_list} = \@unique_sorted_index;
}

#
# Renders the help topic content into XHTML
#
sub help_render {
	my ( $self, $topic ) = @_;
	my $html;

	return ( $html, $topic );
}

#
# Returns the help topic list
#
sub help_list {
	my $self = shift;
	return $self->{help_list};
}

1;

__END__

=head1 NAME

Padre::Plugin::Perl6::PerlHelpProvider - Perl 6 Help Provider

=head1 DESCRIPTION

Perl 6 Help index is built here and rendered.

# Copyright 2008-2009 The Padre development team as listed in Padre.pm.
# LICENSE
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl 5 itself.
