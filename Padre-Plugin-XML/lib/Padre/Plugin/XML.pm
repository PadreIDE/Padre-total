package Padre::Plugin::XML;

use warnings;
use strict;

our $VERSION = '0.01';

use base 'Padre::Plugin';
use Wx ':everything';

sub padre_interfaces {
	'Padre::Plugin' => '0.21',
}

sub menu_plugins_simple {
	'XML' => [
		'Tidy XML', \&tidy_xml,
	];
}

sub tidy_xml {
	my ( $self ) = @_;
	
	my $src = $self->selected_text;
	my $doc = $self->selected_document;
	my $code = ( $src ) ? $src : $doc->text_get;
	
	return unless ( defined $code and length($code) );
	
	require XML::Tidy;
	my $tidy_obj = XML::Tidy->new( xml => $code );
	$tidy_obj->tidy();
	
	my $string = $tidy_obj->toString();
	if ( $src ) {
		my $editor = $self->selected_editor;
	    $editor->ReplaceSelection( $string );
	} else {
		$doc->text_set( $string );
	}
}

1;
__END__

=head1 NAME

Padre::Plugin::XML - L<Padre> and XML

=head1 Tidy XML

use L<XML::Tidy> to tidy XML

=head1 AUTHOR

Fayland Lam, C<< <fayland at gmail.com> >>

=head1 COPYRIGHT & LICENSE

Copyright 2008 Fayland Lam, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
