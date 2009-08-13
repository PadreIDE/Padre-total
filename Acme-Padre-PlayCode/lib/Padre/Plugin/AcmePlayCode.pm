package Padre::Plugin::AcmePlayCode;

use warnings;
use strict;

our $VERSION = '0.11';

use base 'Padre::Plugin';

use Padre::Util   ('_T');

sub padre_interfaces {
	'Padre::Plugin' => '0.26',
}

sub menu_plugins_simple {
    my $self = shift;
	return ('Acme::PlayCode' => [
		_T('Averything'),        sub { $self->play('Averything') },
		_T('DoubleToSingle'),    sub { $self->play('DoubleToSingle') },
		_T('ExchangeCondition'), sub { $self->play('ExchangeCondition') },
		_T('NumberPlus'),        sub { $self->play('NumberPlus') },
		_T('PrintComma'),        sub { $self->play('PrintComma') },
	]);
}

sub play {
	my ( $self, $plugin ) = @_;

	my $main = $self->main;
	my $doc  = $main->current->document;
	return unless $doc;
	my $src  = $main->current->text;
	my $code = $src ? $src : $doc->text_get;

	return unless ( defined $code and length($code) );
	
	require Acme::PlayCode;
	my $playapp = new Acme::PlayCode;	
	$playapp->load_plugin( $plugin );
	
	my $played = $playapp->play($code);
	
	if ( $src ) {
		my $editor = $main->current->editor;
	    $editor->ReplaceSelection( $played );
	} else {
		$doc->text_set( $played );
	}
}

1;
__END__

=head1 NAME

Padre::Plugin::AcmePlayCode - L<Acme::PlayCode> Plugin for L<Padre>

=head1 SYNOPSIS

	$>padre
	Plugins -> AcmePlayCode -> *

=head1 DESCRIPTION

This is a simple plugin to run L<Acme::PlayCode> on your source code.

If there is any selection, just run with the text you selected.

If not, run with the whole text from selected document.

=head1 AUTHOR

Fayland Lam, C<< <fayland at gmail.com> >>

=head1 COPYRIGHT & LICENSE

Copyright 2008 Fayland Lam, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
