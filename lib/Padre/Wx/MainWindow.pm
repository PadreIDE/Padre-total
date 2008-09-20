package Padre::Wx::MainWindow;

use 5.008;
use strict;
use warnings;
use English        qw(-no_match_vars);
use FindBin;
use Cwd            ();
use Carp           ();
use File::Spec     ();
use File::Slurp    ();
use File::Basename ();
use Data::Dumper   ();
use List::Util     ();
use Params::Util   ();
use Wx             qw(:everything);
use Wx::Event      qw(:everything);

use base qw{
	Wx::Frame
	Padre::Wx::Execute
};

use Padre::Util        ();
use Padre::Wx          ();
use Padre::Wx::Text    ();
use Padre::Wx::ToolBar ();

our $VERSION = '0.09';

my $default_dir = Cwd::cwd();



#####################################################################
# Constructor and Accessors

sub new {
	my ($class) = @_;
	my $config  = Padre->ide->get_config;
	Wx::InitAllImageHandlers();

	# Determine the initial frame style
	my $wx_frame_style = wxDEFAULT_FRAME_STYLE;
	if ( $config->{main}->{maximized} ) {
		$wx_frame_style |= wxMAXIMIZE;
	}

	# Create the main panel object
	my $self = $class->SUPER::new(
		undef,
		-1,
		"Padre $Padre::VERSION ",
		[
		    $config->{main}->{left},
		    $config->{main}->{top},
		],
		[
		    $config->{main}->{width},
		    $config->{main}->{height},
		],
		$wx_frame_style,
	);

	# Add some additional attribute slots
	$self->{marker} = {};

	# Create the menu bar
	$self->{menu} = Padre::Wx::Menu->new( $self );
	$self->SetMenuBar( $self->{menu}->{wx} );

	# Create the tool bar
	$self->SetToolBar( Padre::Wx::ToolBar->new($self) );
	$self->GetToolBar->Realize;

	# Create the layout boxes for the main window
	$self->{main_panel} = Wx::SplitterWindow->new(
		$self,
		-1,
		wxDefaultPosition,
		wxDefaultSize,
		wxNO_FULL_REPAINT_ON_RESIZE|wxCLIP_CHILDREN,
	);
	$self->{upper_panel} = Wx::SplitterWindow->new(
		$self->{main_panel},
		-1,
		wxDefaultPosition,
		wxDefaultSize,
		wxNO_FULL_REPAINT_ON_RESIZE|wxCLIP_CHILDREN,
	);

	# Create the right-hand sidebar
	$self->{rightbar} = Wx::ListCtrl->new(
		$self->{upper_panel},
		-1, 
		wxDefaultPosition,
		wxDefaultSize,
		wxLC_SINGLE_SEL|wxLC_NO_HEADER|wxLC_REPORT
	);
	$self->{rightbar}->InsertColumn(0, 'Methods');
	$self->{rightbar}->SetColumnWidth(0, wxLIST_AUTOSIZE);
#    EVT_LIST_ITEM_SELECTED(
#        $self,
#        $self->{rightbar},
#        \&method_selected,
#    );
	EVT_LIST_ITEM_ACTIVATED(
		$self,
		$self->{rightbar},
		\&method_selected_dclick,
	);

	# Create the main notebook for the documents
	$self->{notebook} = Wx::Notebook->new(
		$self->{upper_panel},
		-1,
		wxDefaultPosition,
		wxDefaultSize,
		wxNO_FULL_REPAINT_ON_RESIZE|wxCLIP_CHILDREN,
	);
	EVT_NOTEBOOK_PAGE_CHANGED(
		$self,
		$self->{notebook},
		\&on_panel_changed,
	);

	# Create the bottom-of-screen output textarea
	$self->{output} = Wx::TextCtrl->new(
		$self->{main_panel},
		-1,
		"", 
		wxDefaultPosition,
		wxDefaultSize,
		wxTE_READONLY|wxTE_MULTILINE|wxNO_FULL_REPAINT_ON_RESIZE,
	);

	# Add the bits to the layout
	$self->{main_panel}->SplitHorizontally(
		$self->{upper_panel},
		$self->{output},
		$config->{main}->{height},
	);
	$self->{upper_panel}->SplitVertically(
		$self->{notebook},
		$self->{rightbar},
		$config->{main}->{width} - 200,
	);

	# Create the status bar
	$self->{statusbar} = $self->CreateStatusBar;
	$self->{statusbar}->SetFieldsCount(3);
	$self->{statusbar}->SetStatusWidths(-1, 50, 100);

	# Attach main window events
	EVT_CLOSE( $self, \&on_close_window);
	EVT_KEY_UP( $self, \&on_key );

	#EVT_LEFT_UP( $self, \&on_left_mouse_up );
	#EVT_LEFT_DOWN( $self, \&on_left_mouse_down );
	#EVT_MOTION( $self, sub {print "mot\n"; } );
	#EVT_MOUSE_EVENTS( $self, sub {print "xxx\n"; });
	#EVT_MIDDLE_DOWN( $self, sub {print "xxx\n"; } );
	#EVT_RIGHT_DOWN( $editor, \&on_right_click );
	#EVT_RIGHT_UP( $self, \&on_right_click );
	#EVT_STC_DWELLSTART( $editor, -1, sub {print 1});
	#EVT_MOTION( $editor, sub {print '.'});
	EVT_STC_UPDATEUI( $self, -1,  \&on_stc_update_ui );
	EVT_STC_CHANGE( $self, -1, \&on_stc_change );

	Padre::Wx::Execute->setup( $self );
	#$self->SetIcon( Wx::GetWxPerlIcon() );
	$self->SetIcon( Padre::Wx::icon('new') );

	# Load any default files
	$self->_load_files;

	# we need an event immediately after the window opened
	# (we had an issue that if the default of show_status_bar was false it did not show
	# the status bar which is ok, but then when we selected the menu to show it, it showed
	# at the top)
	# TODO: there might be better ways to fix that issue...
	my $timer = Wx::Timer->new( $self );
	Wx::Event::EVT_TIMER(
	    $self,
	    -1,
		    sub { $_[0]->on_toggle_status_bar },
	);
	$timer->Start( 500, 1 );

	return $self;
}


sub _load_files {
	my $self   =  shift;
	my $ide    = Padre->ide;
	my $config = $ide->get_config;

	# TODO make sure the full path to the file is saved and not
	# the relative path
	my @files  = $ide->get_files;
	if ( @files ) {
		foreach my $f (@files) {
		    if (not File::Spec->file_name_is_absolute($f)) {
		        $f = File::Spec->catfile(Cwd::cwd(), $f);
		    }
		    $self->setup_editor($f);
		}
	} elsif ($config->{startup} eq 'new') {
		$self->setup_editor;
	} elsif ($config->{startup} eq 'nothing') {
		# nothing
	} elsif ($config->{startup} eq 'last') {
		if ($config->{main}->{files} and ref $config->{main}->{files} eq 'ARRAY') {
		    my @files = @{ $config->{main}->{files} };
		    foreach my $f (@files) {
		        $self->setup_editor($f);
		    }
		}
	} else {
		# should never happen
	}
	return;
}





#####################################################################
# Event Handlers

sub method_selected_dclick {
	my ($self, $event) = @_;
	$self->method_selected($event);
	$self->get_current_editor->SetFocus;
	return;
}

sub method_selected {
	my ($self, $event) = @_;
	my $sub = $event->GetItem->GetText;
	return if not defined $sub;
	Padre::Wx::FindDialog::_search(search_term => "sub $sub"); # TODO actually search for sub\s+$sub
	return;
}

=head2 get_current_editor

 my $editor = $self->get_current_editor;
 my $text   = $editor->GetText;

 ... do your stuff with the $text

 $editor->SetText($text);

You can also use the following two methods to make
your editing a atomic in the Undo stack.

 $editor->BeginUndoAction;
 $editor->EndUndoAction;


=cut

sub get_current_editor {
	my $nb = $_[0]->{notebook};
	return $nb->GetPage( $nb->GetSelection );
}

sub on_stc_update_ui {
	my ($self, $event) = @_;
	$self->update_status;
}

sub on_key {
	my ($self, $event) = @_;

	$self->update_status;

	my $mod  = $event->GetModifiers() || 0;
	my $code = $event->GetKeyCode;
	if ($mod == 2) {            # Ctrl
		if ($code == WXK_TAB) {              # Ctrl-TAB  #TODO it is already in the menu
			$self->on_next_pane;
		}
	} elsif ($mod == 6) {                         # Ctrl-Shift
		if ($code == WXK_TAB) {                   # Ctrl-Shift-TAB #TODO it is already in the menu
			$self->on_prev_pane;
		}
	}

	return;
}


sub on_brace_matching {
	my ($self, $event) = @_;

	my $id    = $self->{notebook}->GetSelection;
	my $page  = $self->{notebook}->GetPage($id);
	my $pos1  = $page->GetCurrentPos;
	my $pos2  = $page->BraceMatch($pos1);
	if ($pos2 != -1 ) {   #wxSTC_INVALID_POSITION
		#print "$pos1 $pos2\n";
		#$page->BraceHighlight($pos1, $pos2);
		$page->SetCurrentPos($pos2);
	}
	# TODO: if not found matching brace,
	# we might want to check it at the previous position
	# TODO: or any nearby position.

	return;
}


sub on_comment_out_block {
	my ($self, $event) = @_;

	my $pageid = $self->{notebook}->GetSelection();
	my $page   = $self->{notebook}->GetPage($pageid);
	my $start  = $page->LineFromPosition($page->GetSelectionStart);
	my $end    = $page->LineFromPosition($page->GetSelectionEnd);

	$page->BeginUndoAction;
	for my $line ($start .. $end) {
		# TODO: this should actually depend on language
		# insert #
		my $pos = $page->PositionFromLine($line);
		$page->InsertText($pos, '#');
	}
	$page->EndUndoAction;

	return;
}

sub on_uncomment_block {
	my ($self, $event) = @_;

	my $pageid = $self->{notebook}->GetSelection();
	my $page   = $self->{notebook}->GetPage($pageid);
	my $start  = $page->LineFromPosition($page->GetSelectionStart);
	my $end    = $page->LineFromPosition($page->GetSelectionEnd);

	$page->BeginUndoAction;
	for my $line ($start .. $end) {
		# TODO: this should actually depend on language
		my $first = $page->PositionFromLine($line);
		my $last  = $first+1;
		my $text  = $page->GetTextRange($first, $last);
		if ($text eq '#') {
			$page->SetSelection($first, $last);
			$page->ReplaceSelection('');
		}
	}
	$page->EndUndoAction;

	return;
}


sub on_autocompletition {
	my $self   = shift;

	my $doc    = _DOCUMENT();
    my ($length, @words)  = $doc->autocomplete;
    if ($length =~ /\D/) {
		Wx::MessageBox($length, "Autocompletions error", wxOK);
	}

	if (@words) {
		$doc->editor->AutoCompShow($length, join " ", @words);
	}

	return;
}

sub on_right_click {
	my ($self, $event) = @_;
#print "right\n";
	my @options = qw(abc def);
	my $HEIGHT = 30;
	my $dialog = Wx::Dialog->new( $self, -1, "", [-1, -1], [100, 50 + $HEIGHT * $#options], wxBORDER_SIMPLE);
	#$dialog->;
	foreach my $i (0..@options-1) {
		EVT_BUTTON( $dialog, Wx::Button->new( $dialog, -1, $options[$i], [10, 10+$HEIGHT*$i] ), sub {on_right(@_, $i)} );
	}
	my $ret = $dialog->Show;
#print "ret\n";
	#my $pop = Padre::Wx::Popup->new($self); #, wxSIMPLE_BORDER);
	#$pop->Move($event->GetPosition());
	#$pop->SetSize(300, 200);
	#$pop->Popup;

#Hide
#Destroy

	#my $choices = [ 'This', 'is one of my',  'really', 'wonderful', 'examples', ];
	#my $combo = Wx::BitmapComboBox->new($self,-1,"This",[2,2],[10,10],$choices );

	return;
}

sub on_right {
	my ($self, $event, $val) = @_;
#print "$self $event $val\n";
#print ">", $event->GetClientObject, "<\n";
	$self->Hide;
	$self->Destroy;

	return;
}

sub on_exit {
	$_[0]->Close;
	return;
}

sub on_close_window {
	my $self   = shift;
	my $event  = shift;
	my $config = Padre->ide->get_config;

	my @files;
	foreach my $id ( 0 .. $self->{notebook}->GetPageCount - 1 ) {
		my $doc = _DOCUMENT($id);
		push @files, $doc->filename;
	}
	$config->{main}->{files} = \@files;

	# Check that all files have been saved
	if ( $event->CanVeto ) {
		if ( $config->{startup} eq 'same' ) {
			# Save the files, but don't close
			my $saved = $self->on_save_all;
			unless ( $saved ) {
				# They cancelled at some point
				$event->Veto;
				return;
			}
		} else {
			my $closed = $self->on_close_all;
			unless ( $closed ) {
				# They cancelled at some point
				$event->Veto;
				return;
			}
		}
	}

	# Discover and save the state we want to memorize
	$config->{main}->{maximized} = $self->IsMaximized;
	unless ( $self->IsMaximized ) {
		# Don't save the position when maximized
		(
			$config->{main}->{width},
			$config->{main}->{height},
		) = $self->GetSizeWH;
		(
			$config->{main}->{left},
			$config->{main}->{top},
		) = $self->GetPositionXY;
	}
	Padre->ide->save_config;

	# Clean up secondary windows
	if ( $self->{help} ) {
		$self->{help}->Destroy;
	}

	$event->Skip;

	return;
}

sub on_split_window {
	my ($self) = @_;

	my $editor  = $self->get_current_editor;
	my $id      = $self->{notebook}->GetSelection;
	my $title   = $self->{notebook}->GetPageText($id);
	my $file    = $self->get_current_filename;
	return if not $file;
	my $pointer = $editor->GetDocPointer();
	$editor->AddRefDocument($pointer);

	my $new_editor = Padre::Wx::Text->new( $self->{notebook} );

	#my $new_id = $self->setup_editor();
	#my $new_editor = $self->{notebook}->GetPage( $new_id );
	$new_editor->SetDocPointer($pointer);
	$self->create_tab($new_editor, $file, " $title");

	return;
}

# if the current buffer is empty then fill that with the content of the current file
# otherwise open a new buffer and open the file there
sub setup_editor {
	my ($self, $file) = @_;

	local $self->{_in_setup_editor} = 1;

	# Flush old stuff
	delete $self->{project};

	my $config = Padre->ide->get_config;
	my $editor = Padre::Wx::Text->new( $self->{notebook} );

	#$editor->SetMouseDownCaptures(0);
	#$editor->UsePopUp(0);
	
    $editor->{Padre} = Padre::Document->new(
		editor       => $editor,
		filename     => $file,
	);

    my $title = $editor->{Padre}->get_title;

	$self->_toggle_numbers($editor, $config->{show_line_numbers});
	$self->_toggle_eol($editor, $config->{show_eol});
	$self->set_preferences($editor, $config);

	my $id = $self->create_tab($editor, $file, $title);

	$editor->SetLexer( $editor->{Padre}->lexer );
	$editor->padre_setup( $editor->{Padre}->mimetype );

	$self->{_in_setup_editor} = 0;
	$self->update_status;
	return $id;
}


sub create_tab {
	my ($self, $editor, $file, $title) = @_;

	$self->{notebook}->AddPage($editor, $title, 1); # TODO add closing x
	$editor->SetFocus;

	my $id  = $self->{notebook}->GetSelection;
	my $file_title = $file || $title;
	$self->{menu}->add_alt_n_menu($file_title, $id);

	$self->update_status;

	return $id;
}

# try to open in various ways
#    as full path
#    as path relative to cwd
#    as path to relative to where the current file is
# if we are in a perl file or perl environment also try if the thing might be a name
#    of a module and try to open it locally or from @INC.
sub on_open_selection {
	my ($self, $event) = @_;
	my $selection = $self->_get_selection();
	if (not $selection) {
		Wx::MessageBox("Need to have something selected", "Open Selection", wxOK, $self);
		return;
	}
	my $file;
	if (-e $selection) {
		$file = $selection;
		if (not File::Spec->file_name_is_absolute($file)) {
			$file = File::Spec->catfile(Cwd::cwd(), $file);
			# check if this is still a file?
		}
	} else {
		my $filename
			= File::Spec->catfile(
					File::Basename::dirname($self->get_current_filename),
					$selection);
		if (-e $filename) {
			$file = $filename;
		}
	}
	if (not $file) { # and we are in a Perl environment
		$selection =~ s{::}{/}g;
		$selection .= ".pm";
		my $filename = File::Spec->catfile(Cwd::cwd(), $selection);
		if (-e $filename) {
			$file = $filename;
		} else {
			foreach my $path (@INC) {
				my $filename = File::Spec->catfile( $path, $selection );
				if (-e $filename) {
					$file = $filename;
					last;
				}
			}
		}
	}

	if (not $file) {
		Wx::MessageBox("Could not find file '$selection'", "Open Selection", wxOK, $self);
		return;
	}

	Padre->ide->add_to_recent('files', $file);
	$self->setup_editor($file);

	return;
}

sub on_open {
	my $self = shift;
	my $current_filename = $self->get_current_filename;
	if ($current_filename) {
		$default_dir = File::Basename::dirname($current_filename);
	}
	my $dialog = Wx::FileDialog->new(
		$self,
		"Open file",
		$default_dir,
		"",
		"*.*",
		wxFD_OPEN,
	);
	unless ( Padre::Util::WIN32 ) {
		$dialog->SetWildcard("*");
	}
	if ( $dialog->ShowModal == wxID_CANCEL ) {
		return;
	}
	my $filename = $dialog->GetFilename;
	$default_dir = $dialog->GetDirectory;

	my $file = File::Spec->catfile($default_dir, $filename);
	Padre->ide->add_to_recent('files', $file);

	# If and only if there is only one current file,
	# and it is unused, close it.
	if ( $self->{notebook}->GetPageCount == 1 ) {
		if ( Padre::Document->from_selection->is_unused ) {
			$self->on_close;
		}
	}

	$self->setup_editor($file);

	return;
}

sub on_new {
	my ($self) = @_;
	$self->setup_editor;
	return;
}


=head2 get_current_filename

Returns the name filename of the current buffer.

=cut

sub get_current_filename {
	my ($self) = @_;
    my $doc = _DOCUMENT();
	return $doc->filename;
}

sub set_page_text {
	my ($self, $text) = @_;
	my $id = $self->{notebook}->GetSelection;
	my $page = $self->{notebook}->GetPage($id);
	return $page->SetText($text);
}

sub get_page_text {
	my ($self) = @_;
	my $id = $self->{notebook}->GetSelection;
	my $page = $self->{notebook}->GetPage($id);
	return $page->GetText;
}

# Returns true if saved.
# Returns false if cancelled.
sub on_save_as {
	my $self    = shift;

	my $page_id = $self->{notebook}->GetSelection;
	my $doc     = _DOCUMENT($page_id) or return;
	my $current = $doc->filename;
	if ( defined $current ) {
		$default_dir = File::Basename::dirname($current);
	}
	while (1) {
		my $dialog = Wx::FileDialog->new(
			$self,
			"Save file as...",
			$default_dir,
			"",
			"*.*",
			wxFD_SAVE,
		);
		if ( $dialog->ShowModal == wxID_CANCEL ) {
			return 0;
		}
		my $filename = $dialog->GetFilename;
		$default_dir = $dialog->GetDirectory;
		my $path = File::Spec->catfile($default_dir, $filename);
		if ( -e $path ) {
			my $res = Wx::MessageBox(
				"File already exists. Overwrite it?",
				"Exist",
				wxYES_NO,
				$self,
			);
			if ( $res == wxYES ) {
				$doc->_set_filename($path);
				$doc->set_newline_type($doc->_get_local_newline_type);
				last;
			}
		} else {
			$doc->_set_filename($path);
			$doc->set_newline_type($doc->_get_local_newline_type);
			last;
		}
	}
	$self->_save_buffer($page_id);
	return 1;
}

sub on_save {
	my $self = shift;

	my $page_id = $self->{notebook}->GetSelection;
	my $doc     = _DOCUMENT($page_id) or return;

	if ( $doc->is_new ) {
		return $self->on_save_as($doc);
	}
	if ( $doc->is_modified ) {
		$self->_save_buffer($page_id);
	}

	return;
}

# Returns true if all saved.
# Returns false if cancelled.
sub on_save_all {
	my $self = shift;
	foreach my $id ( 0 .. $self->{notebook}->GetPageCount - 1 ) {
	my $doc = Padre::Document->from_page_id($id);
		$self->on_save( $doc ) or return 0;
	}
	return 1;
}

sub _save_buffer {
	my ($self, $id) = @_;

	my $page         = $self->{notebook}->GetPage($id);
	my $content      = $page->GetText;
    my $doc          = _DOCUMENT($id);
	my $filename     = $doc->filename;
    my $newline_type = $doc->get_newline_type;

	eval {
		File::Slurp::write_file($filename, $content);
	};
	if ($@) {
		Wx::MessageBox("Could not save: $!", "Error", wxOK, $self);
		return;
	}
	Padre->ide->add_to_recent('files', $filename);
	#$self->{notebook}->SetPageText($id, File::Basename::basename($filename));
	$page->SetSavePoint;
	$self->update_status;
	$self->update_methods;

	return; 
}

# Returns true if closed.
# Returns false on cancel.
sub on_close {
	shift->close(@_);
}

sub close {
	my $self = shift;

	my $page_id = $self->{notebook}->GetSelection;
	my $doc     = _DOCUMENT($page_id);
	local $self->{_in_delete_editor} = 1;

	if ( $doc->is_modified and not $doc->is_unused ) {
		my $ret = Wx::MessageBox(
			"File changed. Do you want to save it?",
			$doc->filename || "Unsaved File",
			wxYES_NO|wxCANCEL|wxCENTRE,
			$self,
		);
		if ( $ret == wxYES ) {
			$self->on_save( $doc );
		} elsif ( $ret == wxNO ) {
			# just close it
		} else {
			# wxCANCEL, or when clicking on [x]
			return 0;
		}
	}
	$self->{notebook}->DeletePage($page_id);

	# Update the alt-n menus
	$self->{menu}->remove_alt_n_menu;
	foreach my $i ( 0 .. @{ $self->{menu}->{alt} } - 1 ) {
		my $doc = _DOCUMENT($i);
		my $file = $doc->filename
			|| $self->{notebook}->GetPageText($i);
		$self->{menu}->update_alt_n_menu($file, $i);
	}

	return 1;
}

# Returns true if all closed.
# Returns false if cancelled.
sub on_close_all {
	my $self = shift;
	foreach my $id ( reverse 0 .. $self->{notebook}->GetPageCount - 1 ) {
		$self->close( $id ) or return 0;
	}
	return 1;
}

sub _buffer_changed {
	my ($self, $id) = @_;
	my $page = $self->{notebook}->GetPage($id);
	return $page->GetModify;
}

sub on_goto {
	my ($self) = @_;

	my $dialog = Wx::TextEntryDialog->new( $self, "Line number:", "", '' );
	if ($dialog->ShowModal == wxID_CANCEL) {
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

# highlight a line
#    $page->SetSelection($page->PositionFromLine($line_number), $page->GetLineEndPosition($line_number));

	#$page->SetMarginMask(0, wxSTC_STYLE_LINENUMBER);
	#$page->SetMarginType(0, wxSTC_STYLE_LINENUMBER);

# put circle next to row
#    $page->SetMarginWidth(1, 16);
#    my $fg = Wx::Colour->new( 0xff, 0xff, 0xff );
#    my $bg = Wx::Colour->new( 0x00, 0x00, 0x00 );
#    $page->MarkerDefine(0, wxSTC_MARK_CIRCLE, $fg, $bg);
#    $page->MarkerAdd($line_number, 0);
#
	return;
}

# sub update_methods
sub update_methods {
	my $self    = shift;

	return if $self->{_in_setup_editor};

	my $doc     = _DOCUMENT();
    
	my @methods = $doc->get_functions;
	$self->{rightbar}->DeleteAllItems;
	$self->{rightbar}->InsertStringItem(0, $_) for @methods;
	$self->{rightbar}->SetColumnWidth(0, wxLIST_AUTOSIZE);

	return;
}

sub _get_selection {
	my ($self, $id) = @_;

	if ( not defined $id ) {
		$id  = $self->{notebook}->GetSelection;
	}
	return if $id == -1;
	my $page = $self->{notebook}->GetPage($id);

	return $page->GetSelectedText;
}

sub on_undo { # Ctrl-Z
	my $self = shift;

	my $id   = $self->{notebook}->GetSelection;
	my $page = $self->{notebook}->GetPage($id);
	if ( $page->CanUndo ) {
		$page->Undo;
	}

	return;
}

sub on_redo { # Shift-Ctr-Z
	my $self = shift;

	my $id   = $self->{notebook}->GetSelection;
	my $page = $self->{notebook}->GetPage($id);
	if ( $page->CanRedo ) {
		$page->Redo;
	}

	return;
}

#sub on_copy {
#    my ($self) = @_;
#}
#sub on_paste {
#    my ($self) = @_;
#}

sub on_new_project {
	my ($self) = @_;

	# ask for project type, name and directory
	# create directory call, Module::Starter
	# set current project
	# run
	Wx::MessageBox("Not implemented yet", "Not Yes", wxOK, $self);

	return;
}

sub on_select_project {
	my ($self) = @_;

	#Wx::MessageBox("Not implemented yet", "Not Yes", wxOK, $self);
	#return;
	# popup a window with a list of projects previously selected,
	# and a button to browse for project directory
	# there should also be way to remove a project or to move a project that would
	# probably move the whole directory structure.

	my $config = Padre->ide->get_config;

	my $dialog = Wx::Dialog->new( $self, -1, "Select Project", [-1, -1], [-1, -1]);

	my $box  = Wx::BoxSizer->new(  wxVERTICAL   );
	my $row1 = Wx::BoxSizer->new(  wxHORIZONTAL );
	my $row2 = Wx::BoxSizer->new(  wxHORIZONTAL );
	my $row3 = Wx::BoxSizer->new(  wxHORIZONTAL );
	my $row4 = Wx::BoxSizer->new(  wxHORIZONTAL );

	$box->Add($row1);
	$box->Add($row2);
	$box->Add($row3);
	$box->Add($row4);

	$row1->Add( Wx::StaticText->new( $dialog, -1, 'Select Project Name or type in new one'), 1, wxALL, 3 );

	my @projects = keys %{ $config->{projects} };
	my $choice = Wx::ComboBox->new( $dialog, -1, '', [-1, -1], [-1, -1], \@projects);
	$row2->Add( $choice, 1, wxALL, 3);

	my $dir_selector = Wx::Button->new( $dialog, -1, 'Select Directory');
	$row2->Add($dir_selector, 1, wxALL, 3);

	my $path = Wx::StaticText->new( $dialog, -1, '');
	$row3->Add( $path, 1, wxALL, 3 );

	EVT_BUTTON( $dialog, $dir_selector, sub {on_pick_project_dir($path, @_) } );

	# TODO later we will have other parameters for each project,
	# eg. Perl project/PHP project and each type of project might have its own parameters
	# a Perl project for example should know if it is using Build.Pl or Makefile.PL
	# it might also need to know the version control system to use and there might be other
	# parameters. Some of these should be saved in the central config file, some might need to
	# be local in the development directory and checked in to version control.

	my $ok     = Wx::Button->new( $dialog, wxID_OK,     '');
	my $cancel = Wx::Button->new( $dialog, wxID_CANCEL, '');
	EVT_BUTTON( $dialog, $ok,     sub { $dialog->EndModal(wxID_OK)     } );
	EVT_BUTTON( $dialog, $cancel, sub { $dialog->EndModal(wxID_CANCEL) } );
	$row4->Add($cancel, 1, wxALL, 3);
	$row4->Add($ok,     1, wxALL, 3);

	$dialog->SetSizer($box);
	#$box->SetSizeHints( $self );

	if ($dialog->ShowModal == wxID_CANCEL) {
		return;
	}
	my $project = $choice->GetValue;
	my $dir = $path->GetLabel;
	if (not defined $project or $project eq '') {
		#msg
		return;
	}
	if (not defined $dir or $dir eq '' or not -d $dir) {
		#msg
		return;
	}
	if ($config->{projects}->{$project}) {
		#is changing allowed? how do we notice that it is not one of the already existing names?
	} else {
	   $config->{projects}->{$project}->{dir} = $dir;
	}

	$config->{current_project} = $project;

	return;
}

#sub get_project_name {
#    my ($choice, $self, $event) = @_;
#    my $dialog = Wx::TextEntryDialog->new( $self, "Project Name", "", '' );
#    if ($dialog->ShowModal == wxID_CANCEL) {
#        return;
#    }   
#    my $name = $dialog->GetValue;
#    $dialog->Destroy;
#    $choice->InsertItems([$name], 0);
#    return;
#}
#
sub on_pick_project_dir {
	my ($path, $self, $event) = @_;

	my $dialog = Wx::DirDialog->new( $self, "Select Project Directory", $default_dir);
	if ($dialog->ShowModal == wxID_CANCEL) {
#print "Cancel\n";
		return;
	}
	$default_dir = $dialog->GetPath;

	$path->SetLabel($default_dir);
#print "$default_dir\n";
	return;
}



sub on_test_project {
	my ($self) = @_;
	Wx::MessageBox("Not implemented yet", "Not Yes", wxOK, $self);
}

sub on_nth_pane {
	my ($self, $id) = @_;

	my $page = $self->{notebook}->GetPage($id);
	if ($page) {
	   $self->{notebook}->ChangeSelection($id);
	   $self->update_methods;
	   return 1;
	}

	return;
}

sub on_next_pane {
	my ($self) = @_;

	my $count = $self->{notebook}->GetPageCount;
	return if not $count;

	my $id    = $self->{notebook}->GetSelection;
	if ($id + 1 < $count) {
		$self->on_nth_pane($id + 1);
	} else {
		$self->on_nth_pane(0);
	}
	return;
}
sub on_prev_pane {
	my ($self) = @_;

	my $count = $self->{notebook}->GetPageCount;
	return if not $count;

	my $id    = $self->{notebook}->GetSelection;
	if ($id) {
		$self->on_nth_pane($id - 1);
	} else {
		$self->on_nth_pane($count-1);
	}
	return;
}

sub update_status {
	my ($self) = @_;

	return if $self->{_in_setup_editor} or $self->{_in_delete_editor};

	my $pageid = $self->{notebook}->GetSelection();
	if (not defined $pageid) {
		$self->SetStatusText("", $_) for (0..2);
		return;
	}
#print "Pageid: $pageid\n";
	my $page         = $self->{notebook}->GetPage($pageid);
    #my $doc          = _DOCUMENT($pageid);
	my $doc          = $page->{Padre};
	my $line         = $page->GetCurrentLine;
	my $filename     = $doc->filename || '';
    my $newline_type = $doc->get_newline_type || $doc->_get_local_newline_type();
	my $modified     = $page->GetModify ? '*' : ' ';

	if ($filename) {
#print "set1 ($filename)\n";
		$self->{notebook}->SetPageText($pageid, $modified . File::Basename::basename $filename);
	} else {
		my $text = substr($self->{notebook}->GetPageText($pageid), 1);
#print "set2 $text\n";
		$self->{notebook}->SetPageText($pageid, $modified . $text);
	}
	my $pos = $page->GetCurrentPos;

	my $start = $page->PositionFromLine($line);
	my $char = $pos-$start;

	$self->SetStatusText("$modified $filename", 0);
	$self->SetStatusText($newline_type, 1);

	$self->SetStatusText("L: " . ($line +1) . " Ch: $char", 2);

	return;
}

sub on_panel_changed {
	my ($self) = @_;

	$self->update_status;
	$self->update_methods;

	return;
}


###### preferences and toggle functions

sub on_zoom_in {
	my ($self) = @_;
	$self->zoom(+1);
}
sub on_zoom_out {
	my ($self) = @_;
	$self->zoom(-1);
}
sub on_zoom_reset {
	my ($self) = @_;
	my $editor  = $self->get_current_editor;
	$self->zoom(-1 * $editor->GetZoom);
}
sub zoom {
	my ($self, $val) = @_;

	my $editor = $self->get_current_editor;
	my $zoom   = $editor->GetZoom;

	$zoom += $val;

	foreach my $id ( 0 .. $self->{notebook}->GetPageCount - 1 ) {
		$self->{notebook}->GetPage($id)->SetZoom($zoom);
	}
}


sub on_setup {
	my ($self) = @_;

	my $config = Padre->ide->get_config;

	require Padre::Wx::Preferences;
	Padre::Wx::Preferences->new( $self, $config );

	foreach my $id ( 0 .. $self->{notebook}->GetPageCount - 1 ) {
		my $editor = $self->{notebook}->GetPage($id);
		$self->set_preferences($editor, $config);
	}

	return;
}

sub set_preferences {
	my ($self, $editor, $config) = @_;

	$editor->SetTabWidth( $config->{editor}->{tab_size} );

	return;
}

sub on_toggle_line_numbers {
	my ($self, $event) = @_;

	# Update the configuration
	my $config = Padre->ide->get_config;
	$config->{show_line_numbers} = $event->IsChecked ? 1 : 0;

	# Update the notebook pages
	foreach my $id ( 0 .. $self->{notebook}->GetPageCount - 1 ) {
		my $editor = $self->{notebook}->GetPage($id);
		$self->_toggle_numbers( $editor, $config->{show_line_numbers} );
	}

	return;
}

sub on_toggle_indentation_guide {
	my ($self, $event) = @_;

	my $config = Padre->ide->get_config;
	$config->{editor}->{indentation_guide} = $self->{menu}->{view_indentation_guide}->IsChecked;

	foreach my $id (0 .. $self->{notebook}->GetPageCount -1) {
		my $editor = $self->{notebook}->GetPage($id);
		$editor->SetIndentationGuides( $config->{editor}->{indentation_guide} );
	}
	return;
}

sub on_toggle_eol {
	my ($self, $event) = @_;

	my $config = Padre->ide->get_config;
	$config->{show_eol} = $self->{menu}->{view_eol}->IsChecked ? 1 : 0;

	foreach my $id (0 .. $self->{notebook}->GetPageCount -1) {
		my $editor = $self->{notebook}->GetPage($id);
		$self->_toggle_eol($editor, $config->{show_eol})
	}
	return;
}

sub show_output {
	my ($self) = @_;

	if (not $self->{menu}->{view_output}->IsChecked) {
		$self->{menu}->{view_output}->Check(1);
		$self->_toggle_output(1);
	}

	return;
}

sub on_toggle_show_output {
	my ($self, $event) = @_;

	# Update the output panel
	$self->_toggle_output($self->{menu}->{view_output}->IsChecked);

	return;
}

sub _toggle_output {
	my ($self, $on) = @_;
	my $config = Padre->ide->get_config;
	$self->{main_panel}->SetSashPosition(
		$config->{main}->{height} - ($on ? 300 : 0)
	);
}

sub on_toggle_status_bar {
	my ($self, $event) = @_;
	if ( Padre::Util::WIN32 ) {
		# Status bar always shown on Windows
		return;
	}

	# Update the configuration
	my $config = Padre->ide->get_config;
	$config->{show_status_bar} = $self->{menu}->{view_statusbar}->IsChecked;

	# Update the status bar
	my $status_bar = $self->GetStatusBar;
	if ( $config->{show_status_bar} ) {
		$status_bar->Show;
	} else {
		$status_bar->Hide;
	}

	return;
}


# currently if there are 9 lines we set the margin to 1 width and then
# if another line is added it is not seen well.
# actually I added some improvement allowing a 50% growth in the file
# and requireing a min of 2 width
sub _toggle_numbers {
	my ($self, $editor, $on) = @_;

	$editor->SetMarginWidth(1, 0);
	$editor->SetMarginWidth(2, 0);
	if ($on) {
		my $n = 1 + List::Util::max (2, length ($editor->GetLineCount * 2));
		my $width = $n * $editor->TextWidth(wxSTC_STYLE_LINENUMBER, "9"); # width of a single character
		$editor->SetMarginWidth(0, $width);
		$editor->SetMarginType(0, wxSTC_MARGIN_NUMBER);
	} else {
		$editor->SetMarginWidth(0, 0);
		$editor->SetMarginType(0, wxSTC_MARGIN_NUMBER);
	}

	return;
}

sub _toggle_eol {
	my ($self, $editor, $on) = @_;

	$editor->SetViewEOL($on);

	return;
}

sub convert_to {
	my ($self, $newline_type) = @_;

	my $editor = $self->get_current_editor;
	#$editor->SetEOLMode( $mode{$newline_type} );
	$editor->ConvertEOLs( $Padre::Document::mode{$newline_type} );

	my $id   = $self->{notebook}->GetSelection;
	# TODO: include the changing of file type in the undo/redo actions
	# or better yet somehow fetch it from the document when it is needed.
	my $doc     = _DOCUMENT($id) or return;
    $doc->set_newline_type($newline_type);

	$self->update_status;

	return;
}

sub find_editor_of_file {
	my ($self, $file) = @_;

	foreach my $id (0 .. $self->{notebook}->GetPageCount -1) {
        my $doc = _DOCUMENT($id);
		my $filename = $doc->filename;
		next if not $filename;
		return $id if $filename eq $file;
	}
	return;
}


sub on_stc_change {
	my ($self, $event) = @_;

	return if $self->{_in_setup_editor};
	my $config = Padre->ide->get_config;
	return if not $config->{editor}->{show_calltips};

	my $editor = $self->get_current_editor;

	my $pos    = $editor->GetCurrentPos;
	my $line   = $editor->LineFromPosition($pos);
	my $first  = $editor->PositionFromLine($line);
	my $prefix = $editor->GetTextRange($first, $pos); # line from beginning to current position
	   #$prefix =~ s{^.*?((\w+::)*\w+)$}{$1};
	if ($editor->CallTipActive) {
		$editor->CallTipCancel;
	}

    my $doc = _DOCUMENT();
    my $keywords = $doc->keywords;

	my $regex = join '|', sort {length $a <=> length $b} keys %$keywords;

	my $tip;
	if ( $prefix =~ /($regex)[ (]?$/ ) {
		$tip = $keywords->{$1};
	}
	if ($tip) {
		$editor->CallTipShow($editor->CallTipPosAtStart() + 1, $tip);
	}

	return;
}


sub run_in_padre {
	my $self = shift;

	my $doc  = _DOCUMENT();
	my $code = $doc->text_get;
	eval $code;
	if ($@) {
		Wx::MessageBox("Error: $@", "Self error", wxOK, $self);
		return;
	}

	return;
}


#####################################################################
# Convenience Functions

sub _DOCUMENT {
	if ( Params::Util::_INSTANCE($_[0], 'Wx::CommandEvent') ) {
		shift;
	}
	unless ( @_ ) {
		return Padre::Document->from_selection;
	}
	if ( Params::Util::_INSTANCE($_[0], 'Padre::Document') ) {
		return $_[0];
	} else {
		return Padre::Document->from_page_id($_[0]);
	}
}

1;
