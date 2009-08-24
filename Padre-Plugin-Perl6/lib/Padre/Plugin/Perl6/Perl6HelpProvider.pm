package Padre::Plugin::Perl6::Perl6HelpProvider;

use strict;
use warnings;

# For Perl 6 documentation support
use App::Grok           ();
use Padre::HelpProvider ();

our $VERSION = '0.58';
our @ISA     = 'Padre::HelpProvider';

use Class::XSAccessor accessors => {
	_grok => '_grok', # App::Grok -> Perl 6 Documentation Reader
};


#
# Initialize help
#
sub help_init {
	my $self = shift;

	$self->_grok( App::Grok->new );
}

#
# Renders the help topic content using App::Grok into XHTML
#
sub help_render {
	my ( $self, $topic ) = @_;

	my $grok     = $self->_grok;
	my $html     = $grok->render_target( $topic, 'xhtml' );
	my $location = $grok->locate_target($topic);
	return ( $html, $location );
}

#
# Returns the help topic list
#
sub help_list {
	my ($self) = @_;

	# Return Grok's target index
	my @index = $self->_grok->target_index;

	# Return a unique sorted index
	my %seen = ();
	my @unique_sorted_index = sort grep { !$seen{$_}++ } @index;
	return \@unique_sorted_index;
}

1;

__END__

=head1 NAME

Padre::Plugin::Perl6::PerlHelpProvider - Perl 6 Help Provider

=head1 DESCRIPTION

Perl 6 Help index is built here and rendered.

=head1 AUTHOR

Ahmad M. Zawawi C<< <ahmad.zawawi at gmail.com> >>

Gabor Szabo L<http://szabgab.com/>

=head1 COPYRIGHT AND LICENSE

Copyright 2008-2009 Padre Developers as in Perl6.pm

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl 5 itself.
