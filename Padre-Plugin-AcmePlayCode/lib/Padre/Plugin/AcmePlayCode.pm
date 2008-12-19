package Padre::Plugin::AcmePlayCode;

use warnings;
use strict;

our $VERSION = '0.05';

use base 'Padre::Plugin';

sub padre_interfaces {
	'Padre::Plugin' => '0.18',
}

sub menu_plugins_simple {
	'Acme::PlayCode' => [
		'Averything',        \&averythig,
		'DoubleToSingle',    \&doubletoSingle,
		'ExchangeCondition', \&exchangecondition,
		'NumberPlus',        \&numberplus,
		'PrintComma',        \&printcomma,
	];
}

sub _play {
	my ( $self, $plugin ) = @_;
	
	require Acme::PlayCode;
    my $playapp = new Acme::PlayCode;	
	$playapp->load_plugin( $plugin );
	
	my $code;
	
	my $src = $self->selected_text;
	my $doc = $self->selected_document;
    if ( $src ) {
		$code = $src;
    } else {
		$code = $doc->text_get;
	}
	
	return unless ( defined $code and length($code) );
	
	my $played = $playapp->play($code);
	
	if ( $src ) {
		my $editor = $self->selected_editor;
	    $editor->ReplaceSelection( $played );
	} else {
		$doc->text_set( $played );
	}
}

sub averythig {
    my ($self, $event) = @_;

	_play($self, 'Averything');
}

sub doubletoSingle {
    my ($self, $event) = @_;

	_play($self, 'DoubleToSingle');
}

sub exchangecondition {
    my ($self, $event) = @_;

	_play($self, 'ExchangeCondition');
}

sub numberplus {
    my ($self, $event) = @_;

	_play($self, 'NumberPlus');
}

sub printcomma {
    my ($self, $event) = @_;

	_play($self, 'PrintComma');
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
