package Padre::Plugin::JavaScript;

# Light plugin with no menu entries.
# Provides JavaScript document support.

use 5.008;
use strict;
use warnings;
use Class::Autouse 'Padre::Document::JavaScript';

our $VERSION = '0.24';

use base 'Padre::Plugin';

######################################################################
# Padre::Plugin API Methods

sub padre_interfaces {
	'Padre::Plugin'          => 0.23,
	'Padre::Document'        => 0.21,
}

sub registered_documents {
	'application/javascript' => 'Padre::Document::JavaScript',
	'application/json'       => 'Padre::Document::JavaScript',
}

sub menu_plugins_simple {
	'JavaScript' => [
		'JavaScript Beautifier', \&js_eautifier,
		'JavaScript Minifier',   \&js_minifier,
	];
}

sub js_eautifier {
	my ( $win) = @_;

	my $src = $win->current->text;
	my $doc = $win->current->document;
	my $code = $src ? $src : $doc->text_get;
	return unless ( defined $code and length($code) );

	require JavaScript::Beautifier;
	JavaScript::Beautifier->import('js_beautify');
		
	my $pretty_js = js_beautify( $code, {
        indent_size => 4,
        indent_character => ' ',
    } );
    
    if ( $src ) {
		my $editor = $win->current->editor;
	    $editor->ReplaceSelection( $pretty_js );
	} else {
		$doc->text_set( $pretty_js );
	}
}

sub js_minifier {
	my ( $win) = @_;

	my $src = $win->current->text;
	my $doc = $win->current->document;
	my $code = $src ? $src : $doc->text_get;
	return unless ( defined $code and length($code) );

	require JavaScript::Minifier::XS;
	JavaScript::Minifier::XS->import('minify');
		
	my $mjs = minify( $code );
    
    if ( $src ) {
		my $editor = $win->current->editor;
	    $editor->ReplaceSelection( $mjs );
	} else {
		$doc->text_set( $mjs );
	}
}

1;
__END__

=head1 NAME

Padre::Plugin::JavaScript - L<Padre> and JavaScript

=head1 JavaScript Beautifier

use L<JavaScript::Beautifier> to beautify js

=head1 JavaScript Minifier

use L<JavaScript::Minifier::XS> to minify js

=head1 AUTHOR

Adam Kennedy C<< <adamk@cpan.org> >>

Fayland Lam, C<< <fayland at gmail.com> >>

=head1 COPYRIGHT & LICENSE

Copyright 2008 Adam Kennedy & Fayland Lam all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
