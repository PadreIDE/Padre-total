package Padre::Wx::MainWindow;

use 5.008;
use strict;
use warnings;
use FindBin;
use Cwd                ();
use Carp               ();
use Data::Dumper       ();
use File::Spec         ();
use File::Basename     ();
use List::Util         ();
use Params::Util       ();
use Padre::Util        ();
use Padre::Wx          ();
use Padre::Wx::Editor  ();
use Padre::Wx::ToolBar ();
use Padre::Wx::Output  ();
use Padre::Documents   ();

use Wx::Locale         qw(:default);

use base qw{Wx::Frame};

our $VERSION = '0.15';

my $default_dir = Cwd::cwd();





#####################################################################
# Constructor and Accessors

sub new {
	my $class  = shift;

	my $config = Padre->ide->config;
	Wx::InitAllImageHandlers();

	# Determine the initial frame style
	my $wx_frame_style = Wx::wxDEFAULT_FRAME_STYLE;
	if ( $config->{host}->{main_maximized} ) {
		$wx_frame_style |= Wx::wxMAXIMIZE;
	}

	# Create the main panel object
	my $title = "Padre $Padre::VERSION ";
	if ( $0 =~ /padre$/ ) {
		my $dir = $0;
		$dir =~ s/padre$//;
		if ( -d "$dir.svn" ) {
			$title .= gettext('(running from SVN checkout)');
		}
	}
	my $self = $class->SUPER::new(
		undef,
		-1,
		$title,
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

	# config param has to be ID, not name (e.g.: 87 for 'de'); TODO change this 
	$self->refresh_locale( $config->{host}->{locale} );

	$self->{manager} = Wx::AuiManager->new;
	$self->manager->SetManagedWindow( $self );

	# Add some additional attribute slots
	$self->{marker} = {};

	# Create the menu bar
	$self->{menu} = Padre::Wx::Menu->new( $self );
	$self->SetMenuBar( $self->{menu}->{wx} );

	# Create the tool bar
	$self->SetToolBar( Padre::Wx::ToolBar->new($self) );
	$self->GetToolBar->Realize;

	# Create the status bar
	$self->{statusbar} = $self->CreateStatusBar;
	$self->{statusbar}->SetFieldsCount(4);
	$self->{statusbar}->SetStatusWidths(-1, 100, 50, 100);

	# Create the main notebook for the documents
	$self->{notebook} = Wx::AuiNotebook->new(
		$self,
		-1,
		Wx::wxDefaultPosition,
		Wx::wxDefaultSize,
		Wx::wxAUI_NB_DEFAULT_STYLE | Wx::wxAUI_NB_WINDOWLIST_BUTTON,
	);
	$self->manager->AddPane($self->{notebook}, 
		Wx::AuiPaneInfo->new->Name( "notebook" )
			->CenterPane->Resizable->PaneBorder
			->Dockable->Floatable->PinButton->CaptionVisible->Movable
			->MinimizeButton->PaneBorder->Gripper->MaximizeButton
			->FloatingPosition(100, 100)->FloatingSize(500, 300)
			->Caption( gettext("Files") )->Position( 1 )
		);


	Wx::Event::EVT_AUINOTEBOOK_PAGE_CHANGED(
		$self,
		$self->{notebook},
		sub { $_[0]->refresh_all },
	);
	Wx::Event::EVT_AUINOTEBOOK_PAGE_CLOSE(
		$self,
		$self->{notebook},
		\&on_close,
	);
#	Wx::Event::EVT_DESTROY(
#		$self,
#		$self->{notebook},
#		sub {print "destroy @_\n"; },
#	);
#

	# Create the right-hand sidebar
	$self->{rightbar} = Wx::ListCtrl->new(
		$self,
		-1, 
		Wx::wxDefaultPosition,
		Wx::wxDefaultSize,
		Wx::wxLC_SINGLE_SEL | Wx::wxLC_NO_HEADER | Wx::wxLC_REPORT
	);
	$self->manager->AddPane($self->{rightbar}, 
		Wx::AuiPaneInfo->new->Name( "rightbar" )
			->CenterPane->Resizable->PaneBorder
			->Dockable->Floatable->PinButton->CaptionVisible->Movable
			->MinimizeButton->PaneBorder->Gripper->MaximizeButton
			->FloatingPosition(100, 100)->FloatingSize(100, 400)
			->Caption( gettext("Subs") )->Position( 3 )->Right
		 );
        

	$self->{rightbar}->InsertColumn(0, gettext('Methods'));
	$self->{rightbar}->SetColumnWidth(0, Wx::wxLIST_AUTOSIZE);
	Wx::Event::EVT_LIST_ITEM_ACTIVATED(
		$self,
		$self->{rightbar},
		\&on_function_selected,
	);

	# Create the bottom-of-screen output textarea
	$self->{output} = Padre::Wx::Output->new(
		$self,
	);
	$self->manager->AddPane($self->{output}, 
		Wx::AuiPaneInfo->new->Name( "output" )
			->CenterPane->Resizable->PaneBorder
			->Dockable->Floatable->PinButton->CaptionVisible->Movable
			->MinimizeButton->PaneBorder->Gripper->MaximizeButton
			->FloatingPosition(100, 100)
			->Caption( gettext("Output") )->Position( 2 )->Bottom
		);

	# Special Key Handling
	Wx::Event::EVT_KEY_UP( $self, sub {
		my ($self, $event) = @_;
		$self->refresh_status;
		$self->refresh_toolbar;
		my $mod  = $event->GetModifiers || 0;
		my $code = $event->GetKeyCode;
		if ( $mod == 2 ) { # Ctrl
			# Ctrl-TAB  #TODO it is already in the menu
			$self->on_next_pane if $code == Wx::WXK_TAB;
		} elsif ( $mod == 6 ) { # Ctrl-Shift
			# Ctrl-Shift-TAB #TODO it is already in the menu
			$self->on_prev_pane if $code == Wx::WXK_TAB;
		}
		$event->Skip();
		return;
	} );
	$self->manager->Update;

	# Deal with someone closing the window
	Wx::Event::EVT_CLOSE( $self, \&on_close_window);

	Wx::Event::EVT_STC_UPDATEUI(    $self, -1, \&on_stc_update_ui    );
	Wx::Event::EVT_STC_CHANGE(      $self, -1, \&on_stc_change       );
	Wx::Event::EVT_STC_STYLENEEDED( $self, -1, \&on_stc_style_needed );
	Wx::Event::EVT_STC_CHARADDED(   $self, -1, \&on_stc_char_added   );

	# As ugly as the WxPerl icon is, the new file toolbar image is uglier
	$self->SetIcon( Wx::GetWxPerlIcon() );
	# $self->SetIcon( Padre::Wx::icon('new') );

	# we need an event immediately after the window opened
	# (we had an issue that if the default of main_statusbar was false it did not show
	# the status bar which is ok, but then when we selected the menu to show it, it showed
	# at the top)
	# TODO: there might be better ways to fix that issue...
	my $timer = Wx::Timer->new( $self );
	Wx::Event::EVT_TIMER(
		$self,
		-1,
		\&post_init,
	);
	$timer->Start( 1, 1 );

	return $self;
}

sub manager {
	my ($self) = @_;
	return $self->{manager};
}

# Load any default files
sub load_files {
	my ($self) = @_;

	my $config = Padre->ide->config;
	my $files  = Padre->inst->{ARGV};
	if ( $files and ref($files) eq 'ARRAY' and @$files ) {
		foreach my $f ( @$files ) {
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
	return;
}

sub post_init { 
	my ($self) = @_;

	$self->load_files;

	$self->on_toggle_status_bar;
	$self->refresh_all;

	my $output = $self->{menu}->{view_output}->IsChecked;
	# First we show the output window and then hide it if necessary
	# in order to avoide some weird visual artifacts (empty square at
	# top left part of the whole application)
	# TODO maybe some users want to make sure the output window is always
	# off at startup.
	$self->show_output(1);
	$self->show_output($output) if not $output;

	return;
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

sub no_refresh {
	$_[0]->{_no_refresh};
}

sub refresh_all {
	my ($self) = @_;

	return if $self->no_refresh;

	my $doc  = $self->selected_document;
	$self->refresh_locale;
	$self->refresh_menu;
	$self->refresh_toolbar;
	$self->refresh_status;
	$self->refresh_methods;
	
	my $id = $self->{notebook}->GetSelection();
	if (defined $id and $id >= 0) {
		$self->{notebook}->GetPage($id)->SetFocus;
	}

	return;
}

sub refresh_locale {
    my $self = shift;
    my $lang = shift || Wx::Locale::GetSystemLanguage;

    $self->{'locale'} = undef;

    $self->{'locale'} = Wx::Locale->new($lang);
    $self->{'locale'}->AddCatalogLookupPathPrefix( Padre::Wx::sharedir('locale') );
    my $langname = $self->{'locale'}->GetCanonicalName();

    my $shortname = $langname ? substr( $langname, 0, 2 ) : 'en'; # only providing default sublangs
    my $filename = Padre::Wx::sharefile( 'locale', $shortname ) . '.mo';

    $self->{'locale'}->AddCatalog($shortname) if -f $filename;

    return;
}

sub refresh_menu {
	my $self = shift;
	return if $self->no_refresh;

	$self->{menu}->refresh;	
}

sub refresh_toolbar {
	my $self = shift;
	return if $self->no_refresh;

	$self->GetToolBar->refresh($self->selected_document);
}

sub refresh_status {
	my ($self) = @_;
	return if $self->no_refresh;

	my $pageid = $self->{notebook}->GetSelection();
	if (not defined $pageid or $pageid == -1) {
		$self->SetStatusText("", $_) for (0..3);
		return;
	}
	my $editor       = $self->{notebook}->GetPage($pageid);
	my $doc          = Padre::Documents->current or return;
	my $line         = $editor->GetCurrentLine;
	my $filename     = $doc->filename || '';
	my $newline_type = $doc->get_newline_type || Padre::Util::NEWLINE;
	my $modified     = $editor->GetModify ? '*' : ' ';

	if ($filename) {
		$self->{notebook}->SetPageText($pageid, $modified . File::Basename::basename $filename);
	} else {
		my $text = substr($self->{notebook}->GetPageText($pageid), 1);
		$self->{notebook}->SetPageText($pageid, $modified . $text);
	}

	my $pos   = $editor->GetCurrentPos;
	my $start = $editor->PositionFromLine($line);
	my $char  = $pos-$start;

	$self->SetStatusText("$modified $filename",             0);
	$self->SetStatusText($doc->mimetype,                    1);
	$self->SetStatusText($newline_type,                     2);
	$self->SetStatusText("L: " . ($line +1) . " Ch: $char", 3);

	return;
}

sub refresh_methods {
	my ($self) = @_;
	return if $self->no_refresh;

	$self->{rightbar}->DeleteAllItems;

	my $doc = $self->selected_document;
	return if not $doc;

	my @methods = $doc->get_functions;
	foreach my $method ( @methods ) {
		$self->{rightbar}->InsertStringItem(0, $method);
	}
	$self->{rightbar}->SetColumnWidth(0, Wx::wxLIST_AUTOSIZE);

	return;
}





#####################################################################
# Introspection

sub selected_document {
	Padre::Documents->current;
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
	my $self = shift;
	my $doc = $self->selected_document or return;
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

# probably need to be combined with run_command
sub on_run_command {
	my $main_window = shift;
	require Padre::Wx::History::TextDialog;
	my $dialog = Padre::Wx::History::TextDialog->new(
		$main_window,
		gettext("Command line"),
		gettext("Run setup"),
		"run_command",
	);
	if ( $dialog->ShowModal == Wx::wxID_CANCEL ) {
		return;
	}
	my $command = $dialog->GetValue;
	$dialog->Destroy;
	unless ( defined $command and $command ne '' ) {
		return;
	}
	$main_window->run_command( $command );
	return;
}

sub run_command {
	my $self   = shift;
	my $cmd    = shift;
	my $config = Padre->ide->config;

	$self->{menu}->disable_run;

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

				$self->{menu}->enable_run;
			},
		);
	}

	# Start the command
	$self->{command} = Wx::Perl::ProcessStream->OpenProcess( $cmd, 'MyName1', $self );
	unless ( $self->{command} ) {
		# Failed to start the command. Clean up.
		$self->{menu}->enable_run;
	}

	return;
}

# This should really be somewhere else, but can stay here for now
sub run_script {
	my $self     = shift;
	my $document = Padre::Documents->current;

	return $self->error(gettext("No open document")) if not $document;

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
	
	if ( not $document->can('get_command') ) {
		return $self->error(gettext("No execution mode was defined for this document"));
	}
	
	my $cmd = eval { $document->get_command };
	if ($@) {
		chomp $@;
		$self->error($@);
		return;
	}
	if ($cmd) {
		$self->run_command( $cmd );
	}
	return;
}

sub debug_perl {
	my $self     = shift;
	my $document = $self->selected_document;
	unless ( $document->isa('Perl::Document::Perl') ) {
		return $self->error(gettext("Not a Perl document"));
	}

	# Check the file name
	my $filename = $document->filename;
	unless ( $filename =~ /\.pl$/i ) {
		return $self->error(gettext("Only .pl files can be executed"));
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
	my $title   = shift || gettext('Message');
	Wx::MessageBox( $message, $title, Wx::wxOK | Wx::wxCENTRE, $self );
	return;
}

sub error {
	my $self = shift;
	$self->message( shift, gettext('Error') );
}





#####################################################################
# Event Handlers

sub on_brace_matching {
	my ($self, $event) = @_;

	my $id    = $self->{notebook}->GetSelection;
	my $page  = $self->{notebook}->GetPage($id);
	my $pos1  = $page->GetCurrentPos;
	my $pos2  = $page->BraceMatch($pos1);
	if ($pos2 == -1 ) {   #Wx::wxSTC_INVALID_POSITION
		if ($pos1 > 0) {
			$pos1--;
			$pos2 = $page->BraceMatch($pos1);
		}
	}

	if ($pos2 != -1 ) {   #Wx::wxSTC_INVALID_POSITION
		#print "$pos1 $pos2\n";
		#$page->BraceHighlight($pos1, $pos2);
		#$page->SetCurrentPos($pos2);
		$page->GotoPos($pos2);
		#$page->MoveCaretInsideView;
	}
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
	my $doc    = $self->selected_document or return;
	my ( $length, @words ) = $doc->autocomplete;
	if ( $length =~ /\D/ ) {
		Wx::MessageBox($length, gettext("Autocompletions error"), Wx::wxOK);
	}
	if ( @words ) {
		$doc->editor->AutoCompShow($length, join " ", @words);
	}
	return;
}

sub on_goto {
	my $self = shift;

	my $dialog = Wx::TextEntryDialog->new( $self, gettext("Line number:"), "", '' );
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

sub on_close_window {
	my $self   = shift;
	my $event  = shift;
	my $config = Padre->ide->config;

	# Save the list of open files
	$config->{host}->{main_files} = [
		map  { $_->filename }
		grep { $_ } 
		map  { Padre::Documents->by_id($_) }
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
	$new_editor->{Document} = $editor->{Document};
	$new_editor->padre_setup;
	$new_editor->SetDocPointer($pointer);
	$new_editor->set_preferences;
	
	$self->create_tab($new_editor, $file, " $title");

	return;
}

# if the current buffer is empty then fill that with the content of the
# current file otherwise open a new buffer and open the file there.
sub setup_editor {
	my ($self, $file) = @_;

	if ($file) {
		my $id = $self->find_editor_of_file($file);
		if (defined $id) {
			$self->on_nth_pane($id);
			return;
		}
	}

	local $self->{_no_refresh} = 1;

	my $config = Padre->ide->config;
	my $editor = Padre::Wx::Editor->new( $self->{notebook} );
	
	$editor->{Document} = Padre::Document->new(
		editor   => $editor,
		filename => $file,
	);

	my $title = $editor->{Document}->get_title;

	$editor->set_preferences;

	my $id = $self->create_tab($editor, $file, $title);

	$editor->padre_setup;

	return $id;
}

sub create_tab {
	my ($self, $editor, $file, $title) = @_;

	$self->{notebook}->AddPage($editor, $title, 1); # TODO add closing x
	$editor->SetFocus;

	my $id  = $self->{notebook}->GetSelection;
	my $file_title = $file || $title;
	$self->{menu}->add_alt_n_menu($file_title, $id);

	$self->refresh_all;

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
		Wx::MessageBox(gettext("Need to have something selected"), gettext("Open Selection"), Wx::wxOK, $self);
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
		Wx::MessageBox(gettext("Could not find file '%s'", $selection), gettext("Open Selection"), Wx::wxOK, $self);
		return;
	}

	Padre::DB->add_recent_files($file);
	$self->setup_editor($file);
	$self->refresh_all;

	return;
}

sub on_open {
	my ($self, $event) = @_;

	my $current_filename = $self->selected_filename;
	if ($current_filename) {
		$default_dir = File::Basename::dirname($current_filename);
	}
	my $dialog = Wx::FileDialog->new(
		$self,
		gettext("Open file"),
		$default_dir,
		"",
		"*.*",
		Wx::wxFD_OPEN,
	);
	unless ( Padre::Util::WIN32 ) {
		$dialog->SetWildcard("*");
	}
	if ( $dialog->ShowModal == Wx::wxID_CANCEL ) {
		return;
	}
	my $filename = $dialog->GetFilename;
	$default_dir = $dialog->GetDirectory;

	my $file = File::Spec->catfile($default_dir, $filename);
	Padre::DB->add_recent_files($file);

	# If and only if there is only one current file,
	# and it is unused, close it.
	if ( $self->{notebook}->GetPageCount == 1 ) {
		if ( Padre::Documents->current->is_unused ) {
			$self->on_close($self);
		}
	}

	$self->setup_editor($file);
	$self->refresh_all;

	return;
}

sub on_reload_file {
	my ($self) = @_;

	my $doc     = $self->selected_document or return;
	$doc->reload;
	
	return;
}

# Returns true if saved.
# Returns false if cancelled.
sub on_save_as {
	my $self    = shift;
	my $doc     = $self->selected_document or return;
	my $current = $doc->filename;
	if ( defined $current ) {
		$default_dir = File::Basename::dirname($current);
	}
	while (1) {
		my $dialog = Wx::FileDialog->new(
			$self,
			gettext("Save file as..."),
			$default_dir,
			"",
			"*.*",
			Wx::wxFD_SAVE,
		);
		if ( $dialog->ShowModal == Wx::wxID_CANCEL ) {
			return 0;
		}
		my $filename = $dialog->GetFilename;
		$default_dir = $dialog->GetDirectory;
		my $path = File::Spec->catfile($default_dir, $filename);
		if ( -e $path ) {
			my $res = Wx::MessageBox(
				gettext("File already exists. Overwrite it?"),
				gettext("Exist"),
				Wx::wxYES_NO,
				$self,
			);
			if ( $res == Wx::wxYES ) {
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
	my $pageid = $self->{notebook}->GetSelection;
	$self->_save_buffer($pageid);

	$doc->set_mimetype( $doc->guess_mimetype );
	$doc->editor->padre_setup;

	$self->refresh_all;

	return 1;
}

sub on_save {
	my $self = shift;

	my $doc    = $self->selected_document or return;

	if ( $doc->is_new ) {
		return $self->on_save_as;
	}
	if ( $doc->is_modified ) {
		my $pageid = $self->{notebook}->GetSelection;
		$self->_save_buffer($pageid);
	}

	return;
}

# Returns true if all saved.
# Returns false if cancelled.
sub on_save_all {
	my $self = shift;
	foreach my $id ( $self->pageids ) {
		my $doc = Padre::Documents->by_id($id);
		$self->on_save( $doc ) or return 0;
	}
	return 1;
}

sub _save_buffer {
	my ($self, $id) = @_;

	my $page         = $self->{notebook}->GetPage($id);
    my $doc          = Padre::Documents->by_id($id) or return;

	if ($doc->has_changed_on_disk) {
		my $ret = Wx::MessageBox(
			gettext("File changed on disk since last saved. Do you want to overwrite it?"),
			$doc->filename || gettext("File not in sync"),
			Wx::wxYES_NO|Wx::wxCENTRE,
			$self,
		);
		return if $ret != Wx::wxYES;
	}
	
	my $error = $doc->save_file;
	if ($error) {
		Wx::MessageBox($error, gettext("Error"), Wx::wxOK, $self);
		return;
	}

	Padre::DB->add_recent_files($doc->filename);
	$page->SetSavePoint;
	$self->refresh_all;

	return; 
}

# Returns true if closed.
# Returns false on cancel.
sub on_close {
	my ($self, $event) = @_;

	# When we get an Wx::AuiNotebookEvent from it will try to close
	# the notebook no matter what. For the other events we have to
	# close the tab manually which we do in the close() function
	# Hence here we don't allow the automatic closing of the window. 
	if ($event and $event->isa('Wx::AuiNotebookEvent')) {
		$event->Veto;
	}
	$self->close;
	$self->refresh_all;
}

sub close {
	my ($self, $id) = @_;

	$id = defined $id ? $id : $self->{notebook}->GetSelection;
	
	return if $id == -1;
	
	my $doc = Padre::Documents->by_id($id) or return;

	local $self->{_no_refresh} = 1;
	

	if ( $doc->is_modified and not $doc->is_unused ) {
		my $ret = Wx::MessageBox(
			gettext("File changed. Do you want to save it?"),
			$doc->filename || gettext("Unsaved File"),
			Wx::wxYES_NO|Wx::wxCANCEL|Wx::wxCENTRE,
			$self,
		);
		if ( $ret == Wx::wxYES ) {
			$self->on_save( $doc );
		} elsif ( $ret == Wx::wxNO ) {
			# just close it
		} else {
			# Wx::wxCANCEL, or when clicking on [x]
			return 0;
		}
	}
	$self->{notebook}->DeletePage($id);

	# Update the alt-n menus
	$self->{menu}->remove_alt_n_menu;
	foreach my $i ( 0 .. @{ $self->{menu}->{alt} } - 1 ) {
		my $doc = Padre::Documents->by_id($i) or return;
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
	return $self->_close_all;
}

sub on_close_all_but_current {
	my $self = shift;
	return $self->_close_all( $self->{notebook}->GetSelection );
}

sub _close_all {
	my ($self, $skip) = @_;

	$self->Freeze;
	foreach my $id ( reverse $self->pageids ) {
		next if defined $skip and $skip == $id;
		$self->close( $id ) or return 0;
	}
	$self->Thaw;
	$self->refresh_all;
	return 1;
}


sub on_nth_pane {
	my ($self, $id) = @_;
	my $page = $self->{notebook}->GetPage($id);
	if ($page) {
	   $self->{notebook}->SetSelection($id);
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

sub on_diff {
	my ( $self ) = @_;
	my $doc = Padre::Documents->current;
	return if not $doc;
	
	use Text::Diff ();
	my $current = $doc->text_get;
	my $file    = $doc->filename;
	return $self->error(gettext("Cannot diff if file was never saved")) if not $file;
	
	my $diff = Text::Diff::diff($file, \$current);
	
	if (not $diff) {
		$diff = gettext("There are no differences\n");
	}
	$self->show_output;
	$self->{output}->clear;
	$self->{output}->AppendText($diff);
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

	Padre::Wx::Dialog::Preferences->run( $self, $config );

	foreach my $editor ( $self->pages ) {
		$editor->set_preferences;
	}

	return;
}


sub on_toggle_line_numbers {
	my ($self, $event) = @_;

	my $config = Padre->ide->config;
	$config->{editor_linenumbers} = $event->IsChecked ? 1 : 0;

	foreach my $editor ( $self->pages ) {
		$editor->show_line_numbers( $config->{editor_linenumbers} );
	}

	return;
}

sub on_toggle_indentation_guide {
	my $self   = shift;

	my $config = Padre->ide->config;
	$config->{editor_indentationguides} = $self->{menu}->{view_indentation_guide}->IsChecked ? 1 : 0;

	foreach my $editor ( $self->pages ) {
		$editor->SetIndentationGuides( $config->{editor_indentationguides} );
	}

	return;
}

sub on_toggle_eol {
	my $self   = shift;

	my $config = Padre->ide->config;
	$config->{editor_eol} = $self->{menu}->{view_eol}->IsChecked ? 1 : 0;

	foreach my $editor ( $self->pages ) {
		$editor->SetViewEOL( $config->{editor_eol} );
	}

	return;
}

sub show_output {
	my $self = shift;
	my $on   = @_ ? $_[0] ? 1 : 0 : 1;
	unless ( $on == $self->{menu}->{view_output}->IsChecked ) {
		$self->{menu}->{view_output}->Check($on);
	}
	if ( $on ) {
		$self->{output}->Show;
	} else {
		$self->{output}->Hide;
	}
	Padre->ide->config->{main_output} = $on;

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

sub convert_to {
	my ($self, $newline_type) = @_;

	my $editor = $self->selected_editor;
	#$editor->SetEOLMode( $mode{$newline_type} );
	$editor->ConvertEOLs( $Padre::Document::mode{$newline_type} );

	my $id   = $self->{notebook}->GetSelection;
	# TODO: include the changing of file type in the undo/redo actions
	# or better yet somehow fetch it from the document when it is needed.
	my $doc     = $self->selected_document or return;
	$doc->set_newline_type($newline_type);

	$self->refresh_status;
	$self->refresh_toolbar;

	return;
}

sub find_editor_of_file {
	my ($self, $file) = @_;
	foreach my $id (0 .. $self->{notebook}->GetPageCount -1) {
        my $doc = Padre::Documents->by_id($id) or return;
		my $filename = $doc->filename;
		next if not $filename;
		return $id if $filename eq $file;
	}
	return;
}

sub run_in_padre {
	my $self = shift;
	my $doc  = $self->selected_document or return;
	my $code = $doc->text_get;
	eval $code;
	if ( $@ ) {
		Wx::MessageBox(gettext("Error: %s", $@), gettext("Self error"), Wx::wxOK, $self);
		return;
	}
	return;
}

sub on_function_selected {
	my ($self, $event) = @_;
	my $sub = $event->GetItem->GetText;
	return if not defined $sub;

	my $doc = $self->selected_document;
	Padre::Wx::Dialog::Find::_search( search_term => $doc->get_function_regex($sub) );
	$self->selected_editor->SetFocus;
	return;
}


## STC related functions

sub on_stc_style_needed {
	my ( $self, $event ) = @_;

	my $doc = Padre::Documents->current or return;
	if ($doc->can('colourise')) {
		$doc->colourise;
	}

}


sub on_stc_update_ui {
	my ($self, $event) = @_;
	
	# check for brace, on current position, higlight the matching brace
	my $editor = $self->selected_editor;
	$editor->highlight_braces;
	$editor->show_calltip;

	$self->refresh_status;
	$self->refresh_toolbar;

	return;
}

sub on_stc_change {
	my ($self, $event) = @_;

	return if $self->no_refresh;

	return;
}

# http://www.yellowbrain.com/stc/events.html#EVT_STC_CHARADDED
# TODO: maybe we need to check this more carefully.
sub on_stc_char_added {
	my ($self, $event) = @_;

	if ($event->GetKey == 10) { # ENTER
		my $editor = $self->selected_editor;
		$editor->autoindent;
	}
	return;
}

1;

# Copyright 2008 Gabor Szabo.
# LICENSE
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl 5 itself.
