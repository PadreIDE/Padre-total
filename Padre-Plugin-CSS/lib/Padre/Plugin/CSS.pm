package Padre::Plugin::CSS;

# ABSTRACT: CSS Support for Padre

use v5.8.7;
use warnings;
use strict;

our $VERSION = '0.15';

use base 'Padre::Plugin';
use Padre::Wx ();

sub padre_interfaces {
	'Padre::Plugin' => 0.47, 'Padre::Document' => 0.47,;
}

sub registered_documents {
	'text/css' => 'Padre::Plugin::CSS::Document',;
}

sub menu_plugins_simple {
	my $self = shift;

	return (
		Wx::gettext('CSS') => [
			Wx::gettext('CSS Minifier'),
			sub { $self->css_minifier },
			Wx::gettext('Validate CSS'),
			sub { $self->validate_css },
			Wx::gettext('Docs') => [
				Wx::gettext('CSS 2.1 specs'),
				sub { Padre::Wx::launch_browser('http://www.w3.org/TR/CSS21/cover.html'); },
				Wx::gettext('CSS 2.1 property list'),
				sub { Padre::Wx::launch_browser('http://www.w3.org/TR/CSS21/propidx.html'); },
			],
		]
	);
}

sub validate_css {
	my ($self) = @_;
	my $main = $self->main;

	my $doc  = $main->current->document;
	my $code = $doc->text_get;

	unless ( $code and length($code) ) {
		Wx::MessageBox( Wx::gettext('No Code'), Wx::gettext('Error'), Wx::wxOK | Wx::wxCENTRE, $main );
	}

	require WebService::Validator::CSS::W3C;
	my $val = WebService::Validator::CSS::W3C->new();
	my $ok = $val->validate( string => $code );

	if ($ok) {
		if ( $val->is_valid ) {
			$self->_output( Wx::gettext("CSS is valid\n") );
		} else {
			my $error_text = Wx::gettext("CSS is not valid\n");
			$error_text .= Wx::gettext("Errors:\n");
			my @errors = $val->errors;
			foreach my $err (@errors) {
				my $message = $err->{message};
				$message =~ s/(^\s+|\s+$)//isg;
				$error_text .= " * $message ($err->{context}) at line $err->{line}\n";
			}
			$self->_output($error_text);
		}
	} else {
		my $error_text = Wx::gettext("Failed to validate the code\n");
		$self->_output($error_text);
	}
}

sub _output {
	my ( $self, $text ) = @_;
	my $main = $self->main;

	$main->show_output(1);
	$main->output->clear;
	$main->output->AppendText($text);
}

sub css_minifier {
	my ($self) = @_;
	my $main = $self->main;

	my $src = $main->current->text;
	my $doc = $main->current->document;
	return unless $doc;
	my $code = $src ? $src : $doc->text_get;
	return unless ( defined $code and length($code) );

	require CSS::Minifier::XS;
	CSS::Minifier::XS->import('minify');

	my $css = minify($code);

	if ($src) {
		my $editor = $main->current->editor;
		$editor->ReplaceSelection($css);
	} else {
		$doc->text_set($css);
	}
}

1;
__END__

=head1 CSS Minifier

use L<CSS::Minifier::XS> to minify css

=head1 Validate CSS

use L<WebService::Validator::CSS::W3C> to validate the CSS

=cut
