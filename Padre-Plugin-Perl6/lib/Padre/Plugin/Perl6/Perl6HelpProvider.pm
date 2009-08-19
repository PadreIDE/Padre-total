package Padre::Plugin::Perl6::PerlHelpProvider;

use strict;
use warnings;

# For Perl 6 documentation support
use App::Grok     ();

our $VERSION = '0.43';
our @ISA     = 'Padre::HelpProvider';

use Class::XSAccessor accessors => {
	_grok       => '_grok',  # App::Grok -> Perl 6 Documentation Reader
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

	my $html     = $self->_grok->render_target( $topic, 'xhtml' );
	my $location = $self->_grok->locate_target($topic);
	return ( $html, $location );
}

#
# Returns the help topic list
#
sub help_list {
	my ($self) = @_;
	return $self->_grok->target_index;
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
