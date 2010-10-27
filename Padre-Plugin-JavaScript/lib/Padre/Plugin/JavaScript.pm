package Padre::Plugin::JavaScript;

# ABSTRACT: L<Padre> and JavaScript

use 5.008;
use strict;
use warnings;
use Class::Autouse 'Padre::Plugin::JavaScript::Document';

use base 'Padre::Plugin';

######################################################################
# Padre::Plugin API Methods

sub padre_interfaces {
	'Padre::Plugin' => 0.47, 'Padre::Document' => 0.47,;
}

sub registered_documents {
	'application/javascript' => 'Padre::Plugin::JavaScript::Document',
		'application/json'   => 'Padre::Plugin::JavaScript::Document',
		;
}

sub plugin_name {
	Wx::gettext('JavaScript');
}

sub menu_plugins_simple {
	my $self = shift;
	return (
		Wx::gettext('JavaScript') => [
			Wx::gettext('JavaScript Beautifier'),   sub { $self->js_eautifier },
			Wx::gettext('JavaScript Minifier'),     sub { $self->js_minifier },
			Wx::gettext('JavaScript Syntax Check'), sub { $self->js_syntax_check },
		]
	);
}

sub js_eautifier {
	my ($self) = @_;
	my ( $main, $src, $doc, $code ) = $self->_get_code; return unless $code;

	require JavaScript::Beautifier;
	JavaScript::Beautifier->import('js_beautify');

	my $pretty_js = js_beautify(
		$code,
		{   indent_size      => 4,
			indent_character => ' ',
		}
	);

	if ($src) {
		my $editor = $main->current->editor;
		$editor->ReplaceSelection($pretty_js);
	} else {
		$doc->text_set($pretty_js);
	}
}

sub js_minifier {
	my ($self) = @_;
	my ( $main, $src, $doc, $code ) = $self->_get_code; return unless $code;

	require JavaScript::Minifier::XS;
	JavaScript::Minifier::XS->import('minify');

	my $mjs = minify($code);

	if ($src) {
		my $editor = $main->current->editor;
		$editor->ReplaceSelection($mjs);
	} else {
		$doc->text_set($mjs);
	}
}

sub js_syntax_check {
	my ($self) = @_;
	my ( $main, $src, $doc, $code ) = $self->_get_code; return unless $code;

	require JE;

	if ( JE->new->parse($code) ) {
		$main->message( Wx::gettext('Syntax ok'), 'Info' );
	} else {
		$main->message( Wx::gettext($@), 'Info' );
	}
}

sub _get_code {
	my ($self) = @_;
	my $main = $self->main;

	my $src = $main->current->text;
	my $doc = $main->current->document;
	return unless $doc;
	my $code = $src ? $src : $doc->text_get;
	return unless ( defined $code and length($code) );
	return ( $main, $src, $doc, $code );
}

1;
__END__

=head1 JavaScript Beautifier

use L<JavaScript::Beautifier> to beautify js

=head1 JavaScript Minifier

use L<JavaScript::Minifier::XS> to minify js
