package Padre::Plugin::Ecliptic::OpenResourceDialog;

use warnings;
use strict;

# package exports and version
our $VERSION   = '0.15';
our @EXPORT_OK = ();

# module imports
use Padre::Wx ();

# is a subclass of Wx::Dialog
use base 'Wx::Dialog';

# accessors
use Class::XSAccessor accessors => {
	_plugin           => '_plugin',           # plugin instance
	_sizer            => '_sizer',            # window sizer
	_search_text      => '_search_text',      # search text control
	_matches_list     => '_matches_list',     # matches list
	_ignore_dir_check => '_ignore_dir_check', # ignore .svn/.git dir checkbox
	_status_text      => '_status_text',      # status label
	_directory        => '_directory',        # searched directory
	_matched_files    => '_matched_files',    # matched files list
	_copy_button      => '_copy_button',      # copy button
};

# -- constructor
sub new {
	my ( $class, $plugin, %opt ) = @_;

	#Check if we have an open file so we can use its directory
	my $main = $plugin->main;
	my $filename = ( defined $main->current->document ) ? $main->current->document->filename : undef;
	my $directory;
	if ($filename) {

		# current document's project or base directory
		$directory = Padre::Util::get_project_dir($filename)
			|| File::Basename::dirname($filename);
	} else {

		# current working directory
		$directory = Cwd::getcwd();
	}

	# create object
	my $self = $class->SUPER::new(
		$main,
		-1,
		Wx::gettext('Open Resource'),
		Wx::wxDefaultPosition,
		Wx::wxDefaultSize,
		Wx::wxDEFAULT_FRAME_STYLE | Wx::wxTAB_TRAVERSAL,
	);

	$self->SetIcon( Wx::GetWxPerlIcon() );
	$self->_directory($directory);
	$self->_plugin($plugin);

	# create dialog
	$self->_create;

	return $self;
}


# -- event handler

#
# handler called when the ok button has been clicked.
#
sub _on_ok_button_clicked {
	my ($self) = @_;

	my $main = Padre->ide->wx->main;

	#Open the selected resources here if the user pressed OK
	my @selections = $self->_matches_list->GetSelections();
	foreach my $selection (@selections) {
		my $filename = $self->_matches_list->GetClientData($selection);

		# Keep the last 20 recently opened resources available
		# and save it to plugin's configuration object
		my $config = $self->_plugin->config_read;
		my @recently_opened = split /\|/, $config->{recently_opened};
		if ( scalar @recently_opened >= 20 ) {
			shift @recently_opened;
		}
		push @recently_opened, $filename;
		my %unique = map { $_, 1 } @recently_opened;
		@recently_opened = keys %unique;
		@recently_opened = sort { File::Basename::fileparse($a) cmp File::Basename::fileparse($b) } @recently_opened;
		$config->{recently_opened} = join '|', @recently_opened;
		$self->_plugin->config_write($config);

		# try to open the file now
		$main->setup_editor($filename);
	}

	$self->Destroy;
}


# -- private methods

#
# create the dialog itself.
#
sub _create {
	my ($self) = @_;

	# create sizer that will host all controls
	my $sizer = Wx::BoxSizer->new(Wx::wxVERTICAL);
	$self->_sizer($sizer);

	# create the controls
	$self->_create_controls;
	$self->_create_buttons;

	# wrap everything in a vbox to add some padding
	$self->SetMinSize( [ 420, 498 ] );
	$self->SetSizer($sizer);


	# focus on the search text box
	$self->_search_text->SetFocus();

	# center the dialog
	$self->Fit;
	$self->CentreOnParent;
}

#
# create the buttons pane.
#
sub _create_buttons {
	my ($self) = @_;
	my $sizer = $self->_sizer;

	my $butsizer = $self->CreateStdDialogButtonSizer( Wx::wxOK | Wx::wxCANCEL );
	$sizer->Add( $butsizer, 0, Wx::wxALL | Wx::wxEXPAND | Wx::wxALIGN_CENTER, 5 );
	Wx::Event::EVT_BUTTON( $self, Wx::wxID_OK, \&_on_ok_button_clicked );
}

#
# create controls in the dialog
#
sub _create_controls {
	my ($self) = @_;

	# search textbox
	my $search_label = Wx::StaticText->new(
		$self, -1,
		Wx::gettext('&Select an item to open (? = any character, * = any string):')
	);
	my $font = $search_label->GetFont;
	$font->SetWeight(Wx::wxFONTWEIGHT_BOLD);
	$search_label->SetFont($font);
	$self->_search_text(
		Wx::TextCtrl->new(
			$self,                 -1,                '',
			Wx::wxDefaultPosition, Wx::wxDefaultSize, Wx::wxBORDER_SIMPLE
		)
	);

	# ignore .svn/.git checkbox
	$self->_ignore_dir_check( Wx::CheckBox->new( $self, -1, Wx::gettext('Ignore CVS/.svn/.git/blib folders') ) );
	$self->_ignore_dir_check->SetValue(1);

	# matches result list
	my $matches_label = Wx::StaticText->new(
		$self, -1,
		Wx::gettext('&Matching Items:')
	);
	$matches_label->SetFont($font);

	$self->_matches_list(
		Wx::ListBox->new(
			$self, -1, Wx::wxDefaultPosition, Wx::wxDefaultSize, [],
			Wx::wxLB_EXTENDED | Wx::wxBORDER_SIMPLE
		)
	);

	# Shows how many items are selected and information about what is selected
	$self->_status_text(
		Wx::TextCtrl->new(
			$self,                 -1,                Wx::gettext('Current Directory: ') . $self->_directory,
			Wx::wxDefaultPosition, Wx::wxDefaultSize, Wx::wxTE_READONLY | Wx::wxBORDER_SIMPLE
		)
	);
	$self->_status_text->SetFont($font);

	my $folder_image = Wx::StaticBitmap->new(
		$self, -1,
		Padre::Wx::Icon::find("places/stock_folder")
	);

	$self->_copy_button(
		Wx::BitmapButton->new(
			$self, -1,
			Padre::Wx::Icon::find("actions/edit-copy")
		)
	);


	my $popup_button = Wx::BitmapButton->new(
		$self, -1,
		Padre::Wx::Icon::find("actions/down")
	);
	my ($skip_rcs_files, $skip_hidden_files, $skip_manifest_skip);
	my $popup_menu = Wx::Menu->new;
	Wx::Event::EVT_MENU(
		$self,
		$skip_rcs_files = $popup_menu->AppendCheckItem( -1, Wx::gettext("Skip CVS/.svn/.git"), ),
		sub { },
	);
	Wx::Event::EVT_MENU(
		$self,
		$skip_hidden_files = $popup_menu->AppendCheckItem( -1, Wx::gettext("Skip hidden files"), ),
		sub { },
	);
	Wx::Event::EVT_MENU(
		$self,
		$skip_manifest_skip = $popup_menu->AppendCheckItem( -1, Wx::gettext("skip MANIFEST.SKIP"), ),
		sub { },
	);

	Wx::Event::EVT_BUTTON(
		$self,
		$popup_button,
		sub {
			my ($self, $event) = @_;
			$self->PopupMenu( 
				$popup_menu, 
				$popup_button->GetPosition->x, 
				$popup_button->GetPosition->y + $popup_button->GetSize->GetHeight);
			}
	);

	my $hb;
	$self->_sizer->AddSpacer(10);
	$self->_sizer->Add( $search_label,            0, Wx::wxALL | Wx::wxEXPAND, 2 );
	$hb = Wx::BoxSizer->new(Wx::wxHORIZONTAL);
	$hb->AddSpacer(2);
	$hb->Add( $self->_search_text,      1, Wx::wxALL | Wx::wxEXPAND, 2 );
	$hb->Add( $popup_button,            0, Wx::wxALL | Wx::wxEXPAND, 2 );
	$hb->AddSpacer(1);
	$self->_sizer->Add( $hb, 0, Wx::wxBOTTOM | Wx::wxEXPAND, 5 );
	$self->_sizer->Add( $self->_ignore_dir_check, 0, Wx::wxALL | Wx::wxEXPAND, 5 );
	$self->_sizer->Add( $matches_label,           0, Wx::wxALL | Wx::wxEXPAND, 2 );
	$self->_sizer->Add( $self->_matches_list,     1, Wx::wxALL | Wx::wxEXPAND, 2 );
	$hb = Wx::BoxSizer->new(Wx::wxHORIZONTAL);
	$hb->AddSpacer(2);
	$hb->Add( $folder_image,       0, Wx::wxALL | Wx::wxEXPAND, 1 );
	$hb->Add( $self->_status_text, 1, Wx::wxALL | Wx::wxEXPAND, 1 );
	$hb->Add( $self->_copy_button, 0, Wx::wxALL | Wx::wxEXPAND, 1 );
	$hb->AddSpacer(1);
	$self->_sizer->Add( $hb, 0, Wx::wxBOTTOM | Wx::wxEXPAND, 5 );
	$self->_setup_events();

	return;
}

#
# Adds various events
#
sub _setup_events {
	my $self = shift;

	Wx::Event::EVT_CHAR(
		$self->_search_text,
		sub {
			my $this  = shift;
			my $event = shift;
			my $code  = $event->GetKeyCode;

			if ( $code == Wx::WXK_DOWN ) {
				$self->_matches_list->SetFocus();
			}

			$event->Skip(1);
		}
	);

	Wx::Event::EVT_CHECKBOX(
		$self,
		$self->_ignore_dir_check,
		sub {

			# restart search
			$self->_search();
			$self->_update_matches_list_box;
		}
	);

	Wx::Event::EVT_TEXT(
		$self,
		$self->_search_text,
		sub {

			if ( not $self->_matched_files ) {
				$self->_search();
			}
			$self->_update_matches_list_box;

			return;
		}
	);

	Wx::Event::EVT_LISTBOX(
		$self,
		$self->_matches_list,
		sub {
			my $self         = shift;
			my @matches      = $self->_matches_list->GetSelections();
			my $num_selected = scalar @matches;
			if ( $num_selected == 1 ) {
				$self->_status_text->SetLabel( $self->_matches_list->GetClientData( $matches[0] ) );
				$self->_copy_button->Enable(1);
			} elsif ( $num_selected > 1 ) {
				$self->_status_text->SetLabel( $num_selected . " items selected" );
				$self->_copy_button->Enable(0);
			} else {
				$self->_status_text->SetLabel('');
				$self->_copy_button->Enable(0);
			}

			return;
		}
	);

	Wx::Event::EVT_LISTBOX_DCLICK(
		$self,
		$self->_matches_list,
		sub {
			$self->_on_ok_button_clicked();
			$self->EndModal(0);
		}
	);

	Wx::Event::EVT_BUTTON(
		$self,
		$self->_copy_button,
		sub {
			my @matches      = $self->_matches_list->GetSelections();
			my $num_selected = scalar @matches;
			if ( $num_selected == 1 ) {
				if ( Wx::wxTheClipboard->Open() ) {
					Wx::wxTheClipboard->SetData(
						Wx::TextDataObject->new( $self->_matches_list->GetClientData( $matches[0] ) ) );
					Wx::wxTheClipboard->Close();
				}
			}
		}
	);

	Wx::Event::EVT_IDLE(
		$self,
		sub {
			$self->_show_recently_opened_resources;

			# focus on the search text box
			$self->_search_text->SetFocus;

			# unregister from idle event
			Wx::Event::EVT_IDLE( $self, undef );
		}
	);
}

#
# Shows the recently opened resources
#
sub _show_recently_opened_resources() {
	my $self = shift;

	my $config = $self->_plugin->config_read;
	my @recently_opened = split /\|/, $config->{recently_opened};
	$self->_matched_files( \@recently_opened );
	$self->_update_matches_list_box;
	$self->_matched_files(undef);
}

#
# Search for files and cache result
#
sub _search() {
	my $self = shift;

	$self->_status_text->SetLabel( Wx::gettext("Reading items. Please wait...") );

	my $ignore_dir = $self->_ignore_dir_check->IsChecked();

	# search and ignore rc folders (CVS,.svn,.git) if the user wants
	require File::Find::Rule;
	my $rule = File::Find::Rule->new;
	if ($ignore_dir) {
		$rule->or(
			$rule->new->directory->name( 'CVS', '.svn', '.git', 'blib' )->prune->discard,
			$rule->new
		);
	}
	$rule->file;

	my $manifest_skip_file = File::Spec->catfile( $self->_directory, 'MANIFEST.SKIP' );
	if ( -e $manifest_skip_file ) {
		use ExtUtils::Manifest qw(maniskip);
		my $skip_check = maniskip($manifest_skip_file);
		my $skip_files = sub {
			my ( $shortname, $path, $fullname ) = @_;
			return not $skip_check->($fullname);
		};
		$rule->exec( \&$skip_files );
	}

	# Generate a sorted file-list based on filename
	my @matched_files =
		sort { File::Basename::fileparse($a) cmp File::Basename::fileparse($b) } $rule->in( $self->_directory );

	$self->_matched_files( \@matched_files );

	$self->_status_text->SetLabel( Wx::gettext("Finished Searching") );

	return;
}

#
# Update matches list box from matched files list
#
sub _update_matches_list_box() {
	my $self = shift;

	my $search_expr = $self->_search_text->GetValue();

	#quote the search string to make it safer
	#and then tranform * and ? into .* and .
	$search_expr = quotemeta $search_expr;
	$search_expr =~ s/\\\*/.*?/g;
	$search_expr =~ s/\\\?/./g;

	#Populate the list box now
	$self->_matches_list->Clear();
	my $pos = 0;
	foreach my $file ( @{ $self->_matched_files } ) {
		my $filename = File::Basename::fileparse($file);
		if ( $filename =~ /^$search_expr/i ) {
			$self->_matches_list->Insert( $filename, $pos, $file );
			$pos++;
		}
	}
	if ( $pos > 0 ) {
		$self->_matches_list->Select(0);
		$self->_status_text->SetLabel( $self->_matches_list->GetClientData(0) );
		$self->_status_text->Enable(1);
		$self->_copy_button->Enable(1);
	} else {
		$self->_status_text->SetLabel('');
		$self->_status_text->Enable(0);
		$self->_copy_button->Enable(0);
	}

	return;
}


1;
