package Padre::Plugin::JavaScript;

# ABSTRACT: JavaScript Support for Padre

use 5.008;
use strict;
use warnings;
use Padre::Plugin ();

our $VERSION = '0.30';
our @ISA     = 'Padre::Plugin';





######################################################################
# Padre::Plugin API Methods

sub plugin_name {
	Wx::gettext('JavaScript');
}

sub padre_interfaces {
	'Padre::Plugin'   => 0.91,
	'Padre::Document' => 0.91,
}

sub registered_documents {
	'application/javascript' => 'Padre::Plugin::JavaScript::Document',
	'application/json'       => 'Padre::Plugin::JavaScript::Document',
}

sub menu_plugins_simple {
	my $self = shift;
	return (
		Wx::gettext('JavaScript') => [
			Wx::gettext('JavaScript Beautifier') => sub {
				$self->js_beautifier;
			},
			Wx::gettext('JavaScript Minifier') => sub {
				$self->js_minifier;
			},
			Wx::gettext('JavaScript Syntax Check') => sub {
				$self->js_syntax_check;
			},
		]
	);
}

sub js_beautifier {
	my $self = shift;
	my ( $main, $src, $doc, $code ) = $self->_get_code;
	return unless $code;

	require JavaScript::Beautifier;
	my $pretty_js = JavaScript::Beautifier::js_beautify(
		$code,
		{
			indent_size      => 4,
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
	my $self = shift;
	my ( $main, $src, $doc, $code ) = $self->_get_code;
	return unless $code;

	require JavaScript::Minifier::XS;
	my $mjs = JavaScript::Minifier::XS::minify($code);

	if ($src) {
		my $editor = $main->current->editor;
		$editor->ReplaceSelection($mjs);
	} else {
		$doc->text_set($mjs);
	}
}

sub js_syntax_check {
	my $self = shift;
	my ( $main, $src, $doc, $code ) = $self->_get_code;
	return unless $code;

	require JE;

	if ( JE->new->parse($code) ) {
		$main->message( Wx::gettext('Syntax ok'), 'Info' );
	} else {
		$main->message( Wx::gettext($@), 'Info' );
	}
}

sub _get_code {
	my $self = shift;
	my $main = $self->main;
	my $src  = $main->current->text;
	my $doc  = $main->current->document or return;
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
