package Padre::Plugin::PDL::Document;

use 5.008;
use strict;
use warnings;
use Padre::Document::Perl ();
use Padre::Logger;

our $VERSION = '0.01';

our @ISA = 'Padre::Document::Perl';

# Override get_indentation_style to
sub get_indentation_style {
	my $self = shift;

	# Highlight PDL keywords after get_indentation_style is called :)
	$self->_highlight_pdl_keywords;

	# continue as normal
	return $self->SUPER::get_indentation_style;
}

# Adds PDL keywords highlighting
sub _highlight_pdl_keywords {
	# TODO remove hack once Padre supports a better way
	require Padre::Plugin::PDL::Util;
	Padre::Plugin::PDL::Util::add_pdl_keywords_highlighting( $_[0], $_[1] );
}

1;

__END__

=pod

=head1 NAME

Padre::Plugin::PDL::Document - Padre PDL-enabled Perl document

=cut