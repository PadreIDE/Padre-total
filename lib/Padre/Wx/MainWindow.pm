package Padre::Wx::MainWindow;

use 5.008;
use strict;
use warnings;
use FindBin;
use Cwd            ();
use Carp           ();
use Data::Dumper   ();
use File::Spec     ();
use File::Slurp    ();
use File::Basename ();
use List::Util     ();
use Params::Util   ();
use Wx             qw(
                   WXK_TAB wxDEFAULT_FRAME_STYLE wxMAXIMIZE wxNO_FULL_REPAINT_ON_RESIZE wxCLIP_CHILDREN 
                   wxLC_SINGLE_SEL wxLC_NO_HEADER wxLC_REPORT wxLIST_AUTOSIZE wxTE_READONLY wxTE_MULTILINE 
                   wxOK wxCENTRE wxFD_OPEN wxID_CANCEL wxFD_SAVE wxYES_NO wxYES wxCANCEL wxNO
                   wxSTC_STYLE_LINENUMBER wxSTC_MARGIN_NUMBER);
use Wx::Event      qw(
                   EVT_LIST_ITEM_ACTIVATED EVT_NOTEBOOK_PAGE_CHANGED EVT_KEY_UP EVT_CLOSE
                   EVT_STC_UPDATEUI EVT_STC_CHANGE EVT_STC_STYLENEEDED);

use base qw{Wx::Frame};

use Padre::Util        ();
use Padre::Wx          ();
use Padre::Wx::Editor  ();
use Padre::Wx::ToolBar ();

our $VERSION = '0.12';

my $default_dir = Cwd::cwd();





#####################################################################
# Constructor and Accessors

sub new {
	my $class  = shift;
	my $files  = Padre->inst->{ARGV};

	my $config = Padre->ide->config;
	Wx::InitAllImageHandlers();

	# Determine the initial frame style
	my $wx_frame_style = Wx::wxDEFAULT_FRAME_STYLE;
	if ( $config->{host}->{main_maximized} ) {
		$wx_frame_style |= Wx::wxMAXIMIZE;
	}

	# Create the main panel object
	my $self = $class->SUPER::new(
		undef,
		-1,
		"Padre $Padre::VERSION ",
		[
		    $config->{host}->{main_left},
		    $config->{host}->{main_top},
		],
		[
		    $config->{host}->{main_width},
		    $config->{host}->{main_height},
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
		Wx::wxDefaultPosition,
		Wx::wxDefaultSize,
		Wx::wxNO_FULL_REPAINT_ON_RESIZE | Wx::wxCLIP_CHILDREN,
	);
	$self->{upper_panel} = Wx::SplitterWindow->new(
		$self->{main_panel},
		-1,
		Wx::wxDefaultPosition,
		Wx::wxDefaultSize,
		Wx::wxNO_FULL_REPAINT_ON_RESIZE | Wx::wxCLIP_CHILDREN,
	);

	# Create the right-hand sidebar
	$self->{rightbar} = Wx::ListCtrl->new(
		$self->{upper_panel},
		-1, 
		Wx::wxDefaultPosition,
		Wx::wxDefaultSize,
		Wx::wxLC_SINGLE_SEL | Wx::wxLC_NO_HEADER | Wx::wxLC_REPORT
	);
	$self->{rightbar}->InsertColumn(0, 'Methods');
	$self->{rightbar}->SetColumnWidth(0, Wx::wxLIST_AUTOSIZE);
	EVT_LIST_ITEM_ACTIVATED(
		$self,
		$self->{rightbar},
		\&on_function_selected,
	);

	# Create the main notebook for the documents
	$self->{notebook} = Wx::Notebook->new(
		$self->{upper_panel},
		-1,
		Wx::wxDefaultPosition,
		Wx::wxDefaultSize,
		Wx::wxNO_FULL_REPAINT_ON_RESIZE | Wx::wxCLIP_CHILDREN,
	);
	EVT_NOTEBOOK_PAGE_CHANGED(
		$self,
		$self->{notebook},
		sub { $_[0]->refresh_all },
	);

	# Create the bottom-of-screen output textarea
	$self->{output} = Wx::TextCtrl->new(
		$self->{main_panel},
		-1,
		"", 
		Wx::wxDefaultPosition,
		Wx::wxDefaultSize,
		Wx::wxTE_READONLY | Wx::wxTE_MULTILINE | Wx::wxNO_FULL_REPAINT_ON_RESIZE,
	);

	# Add the bits to the layout
	$self->{main_panel}->SplitHorizontally(
		$self->{upper_panel},
		$self->{output},
		$self->window_height,
	);
	$self->{upper_panel}->SplitVertically(
		$self->{notebook},
		$self->{rightbar},
		$self->window_width - 200,
	);

	# Create the status bar
	$self->{statusbar} = $self->CreateStatusBar;
	$self->{statusbar}->SetFieldsCount(4);
	$self->{statusbar}->SetStatusWidths(-1, 100, 50, 100);

	# Special Key Handling
	EVT_KEY_UP( $self, sub {
		my ($self, $event) = @_;
		$self->refresh_status;
		$self->refresh_toolbar;
		my $mod  = $event->GetModifiers || 0;
		my $code = $event->GetKeyCode;
		if ( $mod == 2 ) { # Ctrl
			# Ctrl-TAB  #TODO it is already in the menu
			$self->on_next_pane if $code == WXK_TAB;
		} elsif ( $mod == 6 ) { # Ctrl-Shift
			# Ctrl-Shift-TAB #TODO it is already in the menu
			$self->on_prev_pane if $code == WXK_TAB;
		}
		return;
	} );

	# Deal with someone closing the window
	EVT_CLOSE( $self, \&on_close_window);

	EVT_STC_UPDATEUI(    $self, -1, \&Padre::Wx::Editor::on_stc_update_ui    );
	EVT_STC_CHANGE(      $self, -1, \&Padre::Wx::Editor::on_stc_change       );
	EVT_STC_STYLENEEDED( $self, -1, \&Padre::Wx::Editor::on_stc_style_needed );

	# As ugly as the WxPerl icon is, the new file toolbar image is uglier
	$self->SetIcon( Wx::GetWxPerlIcon() );
	# $self->SetIcon( Padre::Wx::icon('new') );

	# Load any default files
	# TODO make sure the full path to the file is saved and not
	# the relative path
	if ( $files and ref($files) eq 'ARRAY' and @$files ) {
		foreach my $f ( @$files ) {
		    if ( not File::Spec->file_name_is_absolute($f) ) {
		        $f = File::Spec->catfile(Cwd::cwd(), $f);
		    }
		    $self->setup_editor($f);
		}
	} elsif ( $config->{main_startup} eq 'new' ) {
		$self->setup_editor;
	} elsif ( $config->{main_startup} eq 'nothing' ) {
		# nothing
	} elsif ( $config->{main_startup} eq 'last' ) {
		if ( $config->{host}->{main_files} ) {
		    foreach my $file ( @{$config->{host}->{main_files}} ) {
		        $self->setup_editor($file);
		    }
		}
	} else {
		# should never happen
	}

	# we need an event immediately after the window opened
	# (we had an issue that if the default of main_statusbar was false it did not show
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





#####################################################################
# Window Methods

sub window_width {
	($_[0]->GetSizeWH)[0];
}

sub window_height {
	($_[0]->GetSizeWH)[1];
}

sub window_left {
	($_[0]->GetPositionXY)[0];
}

sub window_top {
	($_[0]->GetPositionXY)[1];
}





#####################################################################
# Refresh Methods

sub refresh_all {
	my $self = shift;
	my $doc  = _DOCUMENT(shift);
	$self->refresh_menu($doc);
	$self->refresh_toolbar($doc);
	$self->refresh_status($doc);
	$self->refresh_methods($doc);
	return;
}

sub refresh_menu {
	shift->{menu}->refresh(@_);	
}

sub refresh_toolbar {
	shift->GetToolBar->refresh(@_);
}

sub refresh_status {
	my ($self) = @_;

	return if $self->{_in_setup_editor} or $self->{_in_delete_editor};

	my $pageid = $self->{notebook}->GetSelection();
	if (not defined $pageid) {
		$self->SetStatusText("", $_) for (0..2);
		return;
	}
	my $page         = $self->{notebook}->GetPage($pageid);
	my $doc          = $page->{Document} or return;
	my $line         = $page->GetCurrentLine;
	my $filename     = $doc->filename || '';
	my $newline_type = $doc->get_newline_type || Padre::Util::NEWLINE;
	my $modified     = $page->GetModify ? '*' : ' ';

	if ($filename) {
		$self->{notebook}->SetPageText($pageid, $modified . File::Basename::basename $filename);
	} else {
		my $text = substr($self->{notebook}->GetPageText($pageid), 1);
		$self->{notebook}->SetPageText($pageid, $modified . $text);
	}
	my $pos = $page->GetCurrentPos;

	my $start = $page->PositionFromLine($line);
	my $char = $pos-$start;

	$self->SetStatusText("$modified $filename",             0);
	$self->SetStatusText($doc->mimetype,                    1);
	$self->SetStatusText($newline_type,                     2);
	$self->SetStatusText("L: " . ($line +1) . " Ch: $char", 3);

	return;
}

sub refresh_methods {
	my ($self, $doc) = @_;

	return if $self->{_in_setup_editor};

	$doc ||= _DOCUMENT();
	return if not $doc;

	my @methods = $doc->get_functions;
	$self->{rightbar}->DeleteAllItems;
	foreach my $method ( @methods ) {
		$self->{rightbar}->InsertStringItem(0, $method);
	}
	$self->{rightbar}->SetColumnWidth(0, Wx::wxLIST_AUTOSIZE);

	return;
}





#####################################################################
# Introspection

sub selected_document {
	Padre::Document->from_selection;
}

=head2 selected_editor

 my $editor = $self->selected_editor;
 my $text   = $editor->GetText;

 ... do your stuff with the $text

 $editor->SetText($text);

You can also use the following two methods to make
your editing a atomic in the Undo stack.

 $editor->BeginUndoAction;
 $editor->EndUndoAction;


=cut

sub selected_editor {
	my $nb = $_[0]->{notebook};
	return $nb->GetPage( $nb->GetSelection );
}

=head2 selected_filename

Returns the name filename of the current buffer.

=cut

sub selected_filename {
	my $doc = _DOCUMENT() or return;
	return $doc->filename;
}

sub selected_text {
	my $self = shift;
	my $id   = $self->{notebook}->GetSelection;
	return if $id == -1;
	$self->{notebook}->GetPage($id)->GetSelectedText;
}

sub pageids {
	return ( 0 .. $_[0]->{notebook}->GetPageCount - 1 );
}

sub pages {
	my $notebook = $_[0]->{notebook};
	return map { $notebook->GetPage($_) } $_[0]->pageids;
}





#####################################################################
# Process Execution

sub run_command {
	my $self   = shift;
	my $cmd    = shift;
	my $config = Padre->ide->config;

	# Temporarily hard-wire this to the Perl menu
	$self->{menu}->{perl_run_script}->Enable(0);
	$self->{menu}->{perl_run_command}->Enable(0);
	$self->{menu}->{perl_stop}->Enable(1);

	# Prepare the output window for the output
	$self->show_output(1);
	$self->{output}->Remove( 0, $self->{output}->GetLastPosition );

	# If this is the first time a command has been run,
	# set up the ProcessStream bindings.
	unless ( $Wx::Perl::ProcessStream::VERSION ) {
		require Wx::Perl::ProcessStream;
		Wx::Perl::ProcessStream::EVT_WXP_PROCESS_STREAM_STDOUT(
			$self,
			sub {
				$_[1]->Skip(1);
				$_[0]->{output}->AppendText( $_[1]->GetLine . "\n" );
				return;
			},
		);
		Wx::Perl::ProcessStream::EVT_WXP_PROCESS_STREAM_STDERR(
			$self,
			sub {
				$_[1]->Skip(1);
				$_[0]->{output}->AppendText( $_[1]->GetLine . "\n" );
				return;
			},
		);
		Wx::Perl::ProcessStream::EVT_WXP_PROCESS_STREAM_EXIT(
			$self,
			sub {
				$_[1]->Skip(1);
				$_[1]->GetProcess->Destroy;

				# Temporarily hard-wired to the Perl menu
				$self->{menu}->{perl_run_script}->Enable(1);
				$self->{menu}->{perl_run_command}->Enable(1);
				$self->{menu}->{perl_stop}->Enable(0);
			},
		);
	}

	# Start the command
	$self->{command} = Wx::Perl::ProcessStream->OpenProcess( $cmd, 'MyName1', $self );
	unless ( $self->{command} ) {
		# Failed to start the command. Clean up.
		$self->{menu}->{perl_run_script}->Enable(1);
		$self->{menu}->{perl_run_command}->Enable(1);
		$self->{menu}->{perl_stop}->Enable(0);
	}

	return;
}

# This should really be somewhere else, but can stay here for now
sub run_perl {
	my $self     = shift;
	my $document = $self->selected_document;
	unless ( $document->isa('Padre::Document::Perl') ) {
		return $self->error("Not a Perl document");
	}

	# Check the file name
	my $filename = $document->filename;
	unless ( $filename =~ /\.pl$/i ) {
		return $self->error("Only .pl files can be executed");
	}

	# Apply the user's save-on-run policy
	# TODO: Make this code suck less
	my $config = Padre->ide->config;
	if ( $config->{run_save} eq 'same' ) {
		$self->on_save;
	} elsif ( $config->{run_save} eq 'all_files' ) {
		$self->on_save_all;
	} elsif ( $config->{run_save} eq 'all_buffer' ) {
		$self->on_save_all;
	}

	# Run with the same Perl that launched Padre
	my $perl = Padre->perl_interpreter;
	$self->run_command( qq{"$perl" "$filename"} );
}

sub debug_perl {
	my $self     = shift;
	my $document = _DOCUMENT(shift);
	unless ( $document->isa('Perl::Document::Perl') ) {
		return $self->error("Not a Perl document");
	}

	# Check the file name
	my $filename = $document->filename;
	unless ( $filename =~ /\.pl$/i ) {
		return $self->error("Only .pl files can be executed");
	}

	# Apply the user's save-on-run policy
	# TODO: Make this code suck less
	my $config = Padre->ide->config;
	if ( $config->{run_save} eq 'same' ) {
		$self->on_save;
	} elsif ( $config->{run_save} eq 'all_files' ) {
		$self->on_save_all;
	} elsif ( $config->{run_save} eq 'all_buffer' ) {
		$self->on_save_all;
	}

	# Set up the debugger
	my $host = 'localhost';
	my $port = 12345;
	# $self->_setup_debugger($host, $port);
	local $ENV{PERLDB_OPTS} = "RemotePort=$host:$port";

	# Run with the same Perl that launched Padre
	my $perl = Padre->perl_interpreter;
	$self->run_command(qq["$perl" -d "$filename"]);
	
}





#####################################################################
# User Interaction

sub message {
	my $self    = shift;
	my $message = shift;
	my $title   = shift || 'Message';
	Wx::MessageBox( $message, $title, Wx::wxOK | Wx::wxCENTRE, $self );
	return;
}

sub error {
	my $self = shift;
	$self->message( shift, 'Error' );
}





#####################################################################
# Event Handlers


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
	my $doc    = _DOCUMENT() or return;
	my ( $length, @words ) = $doc->autocomplete;
	if ( $length =~ /\D/ ) {
		Wx::MessageBox($length, "Autocompletions error", wxOK);
	}
	if ( @words ) {
		$doc->editor->AutoCompShow($length, join " ", @words);
	}
	return;
}

sub on_close_window {
	my $self   = shift;
	my $event  = shift;
	my $config = Padre->ide->config;

	# Save the list of open files
	$config->{host}->{main_files} = [
		map { $_->filename }
		grep { $_ } map { _DOCUMENT($_) }
		$self->pageids
	];

	# Check that all files have been saved
	if ( $event->CanVeto ) {
		if ( $config->{main_startup} eq 'same' ) {
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
	$config->{host}->{main_maximized} = $self->IsMaximized ? 1 : 0;
	unless ( $self->IsMaximized ) {
		# Don't save the maximized window size
		(
			$config->{host}->{main_width},
			$config->{host}->{main_height},
		) = $self->GetSizeWH;
		(
			$config->{host}->{main_left},
			$config->{host}->{main_top},
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

	my $editor  = $self->selected_editor;
	my $id      = $self->{notebook}->GetSelection;
	my $title   = $self->{notebook}->GetPageText($id);
	my $file    = $self->selected_filename;
	return if not $file;
	my $pointer = $editor->GetDocPointer();
	$editor->AddRefDocument($pointer);

	my $new_editor = Padre::Wx::Editor->new( $self->{notebook} );

	#my $new_id = $self->setup_editor();
	#my $new_editor = $self->{notebook}->GetPage( $new_id );
	$new_editor->SetDocPointer($pointer);
	$self->create_tab($new_editor, $file, " $title");

	return;
}

# if the current buffer is empty then fill that with the content of the
# current file otherwise open a new buffer and open the file there.
sub setup_editor {
	my ($self, $file) = @_;

	local $self->{_in_setup_editor} = 1;

	# Flush old stuff
	delete $self->{project};

	my $config = Padre->ide->config;
	my $editor = Padre::Wx::Editor->new( $self->{notebook} );
	
	$editor->{Document} = Padre::Document->new(
		editor   => $editor,
		filename => $file,
	);

	my $title = $editor->{Document}->get_title;

	$self->_toggle_numbers($editor, $config->{editor_linenumbers});
	$editor->SetViewEOL($config->{editor_eol});
	$self->set_preferences($editor, $config);

	my $id = $self->create_tab($editor, $file, $title);

	$editor->padre_setup;

	$self->{_in_setup_editor} = 0;
	$self->refresh_status;
	$self->refresh_methods( $editor->{Document} );

	return $id;
}

sub create_tab {
	my ($self, $editor, $file, $title) = @_;

	$self->{notebook}->AddPage($editor, $title, 1); # TODO add closing x
	$editor->SetFocus;

	my $id  = $self->{notebook}->GetSelection;
	my $file_title = $file || $title;
	$self->{menu}->add_alt_n_menu($file_title, $id);

	$self->refresh_status;

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
	my $selection = $self->selected_text();
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
					File::Basename::dirname($self->selected_filename),
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

	Padre::DB->add_recent_files($file);
	$self->setup_editor($file);

	return;
}

sub on_open {
	my $self = shift;
	my $current_filename = $self->selected_filename;
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
	Padre::DB->add_recent_files($file);

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

# Returns true if saved.
# Returns false if cancelled.
sub on_save_as {
	my $self    = shift;
	my $pageid = $self->{notebook}->GetSelection;
	my $doc     = _DOCUMENT($pageid) or return;
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
				$doc->set_newline_type(Padre::Util::NEWLINE);
				last;
			}
		} else {
			$doc->_set_filename($path);
			$doc->set_newline_type(Padre::Util::NEWLINE);
			last;
		}
	}
	$self->_save_buffer($pageid);

	$doc->set_mimetype( $doc->guess_mimetype );
	$doc->editor->padre_setup;

	$self->refresh_status;
	$self->refresh_methods;

	return 1;
}

sub on_save {
	my $self = shift;

	my $pageid = $self->{notebook}->GetSelection;
	my $doc     = _DOCUMENT($pageid) or return;

	if ( $doc->is_new ) {
		return $self->on_save_as($doc);
	}
	if ( $doc->is_modified ) {
		$self->_save_buffer($pageid);
	}

	return;
}

# Returns true if all saved.
# Returns false if cancelled.
sub on_save_all {
	my $self = shift;
	foreach my $id ( $self->pageids ) {
		my $doc = Padre::Document->from_pageid($id);
		$self->on_save( $doc ) or return 0;
	}
	return 1;
}

sub _save_buffer {
	my ($self, $id) = @_;

	my $page         = $self->{notebook}->GetPage($id);
	my $content      = $page->GetText;
    my $doc          = _DOCUMENT($id) or return;
	my $filename     = $doc->filename;
    my $newline_type = $doc->get_newline_type;

	eval {
		File::Slurp::write_file($filename, $content);
	};
	if ($@) {
		Wx::MessageBox("Could not save: $!", "Error", wxOK, $self);
		return;
	}
	Padre::DB->add_recent_files($filename);
	#$self->{notebook}->SetPageText($id, File::Basename::basename($filename));
	$page->SetSavePoint;
	$self->refresh_status;
	$self->refresh_methods;

	return; 
}

# Returns true if closed.
# Returns false on cancel.
sub on_close {
	shift->close(@_);
}

sub close {
	my $self = shift;

	my $pageid = $self->{notebook}->GetSelection;
	my $doc     = _DOCUMENT($pageid) or return;
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
	$self->{notebook}->DeletePage($pageid);

	# Update the alt-n menus
	$self->{menu}->remove_alt_n_menu;
	foreach my $i ( 0 .. @{ $self->{menu}->{alt} } - 1 ) {
		my $doc = _DOCUMENT($i) or return;
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
	foreach my $id ( reverse $self->pageids ) {
		$self->close( $id ) or return 0;
	}
	return 1;
}


sub on_nth_pane {
	my ($self, $id) = @_;
	my $page = $self->{notebook}->GetPage($id);
	if ($page) {
	   $self->{notebook}->ChangeSelection($id);
	   $self->refresh_status;
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

###### preferences and toggle functions

sub zoom {
	my $self = shift;
	my $zoom = $self->selected_editor->GetZoom + shift;
	foreach my $page ( $self->pages ) {
		$page->SetZoom($zoom);
	}
}

sub on_preferences {
	my $self   = shift;
	my $config = Padre->ide->config;

	require Padre::Wx::Preferences;
	Padre::Wx::Preferences->run( $self, $config );

	foreach my $page ( $self->pages ) {
		$self->set_preferences($page, $config);
	}

	return;
}

sub set_preferences {
	my ($self, $editor, $config) = @_;
	$editor->SetTabWidth( $config->{editor_tabwidth} );
	return;
}

sub on_toggle_line_numbers {
	my ($self, $event) = @_;

	# Update the configuration
	my $config = Padre->ide->config;
	$config->{editor_linenumbers} = $event->IsChecked ? 1 : 0;

	# Update the notebook pages
	foreach my $page ( $self->pages ) {
		$self->_toggle_numbers( $page, $config->{editor_linenumbers} );
	}

	return;
}

sub on_toggle_indentation_guide {
	my $self   = shift;
	my $config = Padre->ide->config;
	$config->{editor_indentationguides} = $self->{menu}->{view_indentation_guide}->IsChecked ? 1 : 0;
	foreach my $page ( $self->pages ) {
		$page->SetIndentationGuides( $config->{editor_indentationguides} );
	}
	return;
}

sub on_toggle_eol {
	my $self   = shift;
	my $config = Padre->ide->config;
	$config->{editor_eol} = $self->{menu}->{view_eol}->IsChecked ? 1 : 0;
	foreach my $page ( $self->pages ) {
		$page->SetViewEOL( $config->{editor_eol} );
	}
	return;
}

sub show_output {
	my $self = shift;
	my $on   = shift;
	unless ( $on == $self->{menu}->{view_output}->IsChecked ) {
		$self->{menu}->{view_output}->Check($on);
	}
	$self->{main_panel}->SetSashPosition(
		$self->window_height - ($on ? 300 : 0)
	);
	return;
}

sub on_toggle_status_bar {
	my ($self, $event) = @_;
	if ( Padre::Util::WIN32 ) {
		# Status bar always shown on Windows
		return;
	}

	# Update the configuration
	my $config = Padre->ide->config;
	$config->{main_statusbar} = $self->{menu}->{view_statusbar}->IsChecked ? 1 : 0;

	# Update the status bar
	my $status_bar = $self->GetStatusBar;
	if ( $config->{main_statusbar} ) {
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

sub convert_to {
	my ($self, $newline_type) = @_;

	my $editor = $self->selected_editor;
	#$editor->SetEOLMode( $mode{$newline_type} );
	$editor->ConvertEOLs( $Padre::Document::mode{$newline_type} );

	my $id   = $self->{notebook}->GetSelection;
	# TODO: include the changing of file type in the undo/redo actions
	# or better yet somehow fetch it from the document when it is needed.
	my $doc     = _DOCUMENT($id) or return;
	$doc->set_newline_type($newline_type);

	$self->refresh_status;

	return;
}

sub find_editor_of_file {
	my ($self, $file) = @_;
	foreach my $id (0 .. $self->{notebook}->GetPageCount -1) {
        my $doc = _DOCUMENT($id) or return;
		my $filename = $doc->filename;
		next if not $filename;
		return $id if $filename eq $file;
	}
	return;
}

sub run_in_padre {
	my $self = shift;
	my $doc  = _DOCUMENT() or return;
	my $code = $doc->text_get;
	eval $code;
	if ( $@ ) {
		Wx::MessageBox("Error: $@", "Self error", wxOK, $self);
		return;
	}
	return;
}

sub on_function_selected {
	my ($self, $event) = @_;
	my $sub = $event->GetItem->GetText;
	return if not defined $sub;

	require Padre::Wx::FindDialog;
	my $doc = _DOCUMENT();
	Padre::Wx::FindDialog::_search( search_term => $doc->get_function_regex($sub) );
	$self->selected_editor->SetFocus;
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
		return Padre::Document->from_pageid($_[0]);
	}
}

1;
