package Padre::Wx::GoToLine;

use 5.008;
use strict;
use warnings;

# GoTo Line widget of Padre

use Padre::Wx  ();

our $VERSION = '0.14';


sub on_goto {
	my ($self) = @_;

	my $dialog = Wx::TextEntryDialog->new( $self, "Line number:", "", '' );
	if ($dialog->ShowModal == Wx::wxID_CANCEL) {
		return;
	}   
	my $line_number = $dialog->GetValue;
	$dialog->Destroy;
	return if not defined $line_number or $line_number !~ /^\d+$/;
	#what if it is bigger than buffer?

	my $id   = $self->{notebook}->GetSelection;
	my $page = $self->{notebook}->GetPage($id);

	$line_number--;
	$page->GotoLine($line_number);

	return;
}

1;

# Copyright 2008 Gabor Szabo.
# LICENSE
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl 5 itself.
