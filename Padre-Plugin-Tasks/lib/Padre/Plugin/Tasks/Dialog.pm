package Padre::Plugin::Tasks::Dialog;

use strict;
use warnings;

use Padre::Wx                              ();
use Padre::Wx::Dialog                      ();
use Padre::Util   ('_T');

use Wx::TreeListCtrl 0.06;

our $VERSION = '0.01';
our @ISA     = 'Padre::Wx::Dialog';


my $dialog;
my $list;

sub show {
	my $class = shift;
	if (not $dialog) {
		$dialog = $class->dialog;
	}
	
	my $idx = $list->InsertStringItem( 1, 1 );
	$list->SetItemData( $idx, 0 );
	$list->SetItem( $idx, 1, "2009.08.08" );
	$list->SetItem( $idx, 2, "Text" );


	$dialog->Show;
}

sub dialog {
	my $class = shift;
	my $main = Padre->ide->wx->main;
	my $dialog = Wx::Dialog->new(
		$main,
		-1,
		Wx::gettext('TODO'),
		Wx::wxDefaultPosition,
		#Wx::wxDefaultSize,
		[500,300],
		Wx::wxCAPTION | Wx::wxRESIZE_BORDER | Wx::wxCLOSE_BOX | Wx::wxSYSTEM_MENU,
	);

	my $dialog_sizer = Wx::BoxSizer->new(Wx::wxVERTICAL);
	$list = Wx::ListView->new(
		$dialog,
		-1,
		Wx::wxDefaultPosition,
		#Wx::wxDefaultSize,
		[400,200],
		Wx::wxLC_REPORT | Wx::wxLC_SINGLE_SEL
	);
	$list->InsertColumn( $_, _get_title($_) ) for 0 .. 3;

	$list->SetColumnWidth( 0, 20 );
	$list->SetColumnWidth( 1, 80 );
	$list->SetColumnWidth( 2, 200 );
	#$self->SetColumnWidth( 3, $width2 );

	Wx::Event::EVT_LIST_ITEM_ACTIVATED(
		$list, $list,
		\&on_list_item_activated
	);

	return $dialog;
}
sub on_list_item_activated {
	my $self   = shift;
	my $event  = shift;
	my $line   = $event->GetItem->GetText;
	print "L $line\n";
}

sub _get_title {
	my $c = shift;

	return Wx::gettext('ID')            if $c == 0;
	return Wx::gettext('Start')         if $c == 1;
	return Wx::gettext('Title')         if $c == 2;
	return Wx::gettext('Association')   if $c == 3;

	die "invalid value '$c'";
}

1;

=head1 AUTHOR

Gabor Szabo L<http://szabgab.com/>

=head1 COPYRIGHT AND LICENSE

Copyright 2008-2009 Padre Developers as in Perl6.pm

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl 5 itself.

=cut

