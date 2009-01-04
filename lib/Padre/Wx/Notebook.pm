package Padre::Wx::Notebook;

use strict;
use warnings;
use Padre::Wx ();

our $VERSION = '0.23';
our @ISA     = 'Wx::AuiNotebook';

sub new {
	my $class = shift;
	my $main  = shift;
	my $self  = $class->SUPER::new(
		$main,
		Wx::wxID_ANY,
		Wx::wxDefaultPosition,
		Wx::wxDefaultSize,
		Wx::wxAUI_NB_TOP
		| Wx::wxAUI_NB_SCROLL_BUTTONS
		| Wx::wxAUI_NB_CLOSE_ON_ACTIVE_TAB
		| Wx::wxAUI_NB_WINDOWLIST_BUTTON,
	);

	# Add ourself to the main window
	$main->manager->AddPane(
		$self,
		Wx::AuiPaneInfo->new
			->Name('editorpane')
			->CenterPane
			->Resizable
			->PaneBorder
			->Dockable
			->Position(1)
	);
	$main->manager->caption_gettext('editorpane' => 'Files');

	Wx::Event::EVT_AUINOTEBOOK_PAGE_CHANGED(
		$main,
		$self,
		sub {
			shift->on_notebook_page_changed(@_);
		},
	);

	Wx::Event::EVT_AUINOTEBOOK_PAGE_CLOSE(
		$main,
		$self,
		sub {
			shift->on_close(@_);
		},
	);

	return $self;
}

sub main {
	$_[0]->GetParent;
}

1;
