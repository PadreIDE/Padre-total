package Padre::Plugin::CSS;

use warnings;
use strict;

our $VERSION = '0.04';

use base 'Padre::Plugin';
use Wx ':everything';

sub padre_interfaces {
	'Padre::Plugin'   => 0.23,
	'Padre::Document' => 0.21,
}

sub registered_documents {
	'text/css' => 'Padre::Document::CSS',
}

sub menu_plugins_simple {
	'CSS' => [
	    'CSS Minifier',   \&css_minifier,
		'Validate CSS',   \&validate_css,
	];
}

sub validate_css {
	my ( $self ) = @_;
	
	my $doc  = $self->current->document;
	my $code = $doc->text_get;
	
	unless ( $code and length($code) ) {
		Wx::MessageBox( 'No Code', 'Error', Wx::wxOK | Wx::wxCENTRE, $self );
	}
	
	require WebService::Validator::CSS::W3C;
	my $val = WebService::Validator::CSS::W3C->new();
	my $ok  = $val->validate(string => $code);

	if ($ok) {
		if ( $val->is_valid ) {
			_output( $self, "CSS is valid\n" );
		} else {
			my $error_text = "CSS is not valid\n";
			$error_text .= "Errors:\n";
			my @errors = $val->errors;
			foreach my $err (@errors) {
				my $message = $err->{message};
				$message =~ s/(^\s+|\s+$)//isg;
				$error_text .= " * $message ($err->{context}) at line $err->{line}\n";
			}
			_output( $self, $error_text );
		}
	} else {
		my $error_text = sprintf("Failed to validate the code\n");
        _output( $self, $error_text );
	}
}

sub _output {
	my ( $self, $text ) = @_;
	
	$self->show_output;
	$self->{gui}->{output_panel}->clear;
	$self->{gui}->{output_panel}->AppendText($text);
}

sub css_minifier {
	my ( $win) = @_;

	my $src = $win->current->text;
	my $doc = $win->current->document;
	my $code = $src ? $src : $doc->text_get;
	return unless ( defined $code and length($code) );

	require CSS::Minifier::XS;
	CSS::Minifier::XS->import('minify');
		
	my $css = minify( $code );
    
    if ( $src ) {
		my $editor = $win->current->editor;
	    $editor->ReplaceSelection( $css );
	} else {
		$doc->text_set( $css );
	}
}

1;
__END__

=head1 NAME

Padre::Plugin::CSS - L<Padre> and CSS

=head1 CSS Minifier

use L<CSS::Minifier::XS> to minify css

=head1 Validate CSS

use L<WebService::Validator::CSS::W3C> to validate the CSS

=head1 AUTHOR

Fayland Lam, C<< <fayland at gmail.com> >>

=head1 COPYRIGHT & LICENSE

Copyright 2008 Fayland Lam, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
