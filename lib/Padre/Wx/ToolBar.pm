package Padre::Wx::ToolBar;

use 5.008;
use strict;
use warnings;

use Padre::Wx    ();
use File::Spec::Functions qw(catfile);

our $VERSION = '0.14';
our @ISA     = 'Wx::ToolBar';

sub new {
	my $class  = shift;
	my $parent = shift;
	my $self   = $class->SUPER::new(
		$parent,
		-1,
		Wx::wxDefaultPosition,
		Wx::wxDefaultSize,
		Wx::wxNO_BORDER | Wx::wxTB_HORIZONTAL | Wx::wxTB_FLAT | Wx::wxTB_DOCKABLE,
		5050,
	);

	# Automatically populate
	$self->AddTool( Wx::wxID_NEW,   '', Padre::Wx::tango(catfile('actions', 'document-new.png')),  'New File'  ); 
	$self->AddTool( Wx::wxID_OPEN,  '', Padre::Wx::tango(catfile('actions', 'document-open.png')), 'Open File' ); 
	$self->AddTool( Wx::wxID_SAVE,  '', Padre::Wx::tango(catfile('actions', 'document-save.png')), 'Save File' );
	$self->AddTool( Wx::wxID_CLOSE, '', Padre::Wx::tango(catfile('emblems', 'emblem-unreadable.png')) , 'Close File' );
	$self->AddSeparator;
	# TODO, how can we make sure these numbers are unique?
	$self->AddTool( 1000, '', Padre::Wx::tango(catfile('actions', 'bookmark-new.png')), 'Bookmark' );
	Wx::Event::EVT_TOOL($parent, 1000, sub { Padre::Wx::Dialog::Bookmarks->set_bookmark($_[0]) } );

	return $self;
}

sub refresh {
	my $self    = shift;
	my $doc     = shift;

	my $enabled = !! ( $doc and $doc->is_modified );
	$self->EnableTool( Wx::wxID_SAVE, $enabled );
	return 1;
}

1;

# Copyright 2008 Gabor Szabo.
# LICENSE
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl 5 itself.
