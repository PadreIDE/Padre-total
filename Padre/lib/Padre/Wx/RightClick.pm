package Padre::Wx::RightClick;

use 5.008;
use strict;
use warnings;
use Padre::Wx ();

our $VERSION = '0.26';

sub on_right_click {
	my ($self, $event) = @_;
	my @options = qw(abc def);
	my $HEIGHT = 30;
	my $dialog = Wx::Dialog->new(
		$self,
		-1,
		"",
		[ -1, -1 ],
		[ 100, 50 + $HEIGHT * $#options ],
		Wx::wxBORDER_SIMPLE,
	);
	foreach my $i ( 0 .. @options - 1 ) {
		Wx::Event::EVT_BUTTON(
			$dialog,
			Wx::Button->new( $dialog, -1, $options[$i], [ 10, 10 + $HEIGHT * $i ] ),
			sub {
				on_right(@_, $i)
			}
		);
	}
	my $ret = $dialog->Show;
	return;
}

sub on_right {
	my ($self, $event, $val) = @_;
	$self->Hide;
	$self->Destroy;
	return;
}

1;

# Copyright 2008 Gabor Szabo.
# LICENSE
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl 5 itself.
