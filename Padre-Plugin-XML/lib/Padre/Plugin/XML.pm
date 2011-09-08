package Padre::Plugin::XML;

use v5.8.7;
use warnings;
use strict;

our $VERSION = '0.11';

use base 'Padre::Plugin';
use Padre::Wx ();

sub padre_interfaces {
	'Padre::Plugin' => 0.81, 'Padre::Document' => 0.81;
}

sub registered_documents {
	'text/xml' => 'Padre::Document::XML',;
}

sub menu_plugins_simple {
	my $self = shift;
	return (
		'XML' => [
			Wx::gettext('Tidy XML'), sub { $self->tidy_xml },
		]
	);
}

sub tidy_xml {
	my ($self) = @_;

	my $main = $self->main;

	my $src = $main->current->text;
	my $doc = $main->current->document;

	unless ( $doc and $doc->isa('Padre::Document::XML') ) {
		$main->message( Wx::gettext('This is not an XML document! ') . ref $doc );
		return;
	}

	my $code = ($src) ? $src : $doc->text_get;

	return unless ( defined $code and length($code) );

	require XML::Tidy;

	my $tidy_obj = '';
	my $string   = '';
	eval {
		$tidy_obj = XML::Tidy->new( xml => $code );
		$tidy_obj->tidy();

		$string = $tidy_obj->toString();
	};

	if ( !$@ ) {
		if ($src) {
			$string =~ s/\A<\?xml.+?\?>\r?\n?//o;
			my $editor = $main->current->editor;
			$editor->ReplaceSelection($string);
		} else {
			$doc->text_set($string);
		}
	} else {
		$main->message( Wx::gettext("Tidying failed due to error(s):") . "\n\n" . $@ );
	}

	return;
}

sub editor_enable {
	my $self     = shift;
	my $editor   = shift;
	my $document = shift;

	if ( $document->isa('Padre::Document::XML') ) {
		$editor->SetProperty( 'fold.html', '1' );
	}

	return 1;
}

1;
__END__

=head1 NAME

Padre::Plugin::XML - L<Padre> and XML

=head1 Tidy XML

use L<XML::Tidy> to tidy XML

=head1 AUTHOR

Fayland Lam C<< <fayland at gmail.com> >>

Heiko Jansen C<< <heiko_jansen@web.de> >>

Alexandr Ciornii

Zeno Gantner

=head1 COPYRIGHT & LICENSE

Copyright 2008-2010 Fayland Lam, Heiko Jansen, Alexandr Ciornii,
                    Zeno Gantner

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
