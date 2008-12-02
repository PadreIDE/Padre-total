package Padre::Wx::MainWindow;

use 5.008;

# This is somewhat disturbing but necessary to prevent
# Test::Compile from breaking. The compile tests run
# perl -v lib/Padre/Wx/MainWindow.pm which first compiles
# the module as a script (i.e. no %INC entry created)
# and then again when Padre::Wx::MainWindow is required
# from another module down the dependency chain.
# This used to break with subroutine redefinitions.
# So to prevent this, we force the creating of the correct
# %INC entry when the file is first compiled. -- Steffen
BEGIN {$INC{"Padre/Wx/MainWindow.pm"} ||= __FILE__}

use strict;
use warnings;
use FindBin;
use Cwd                ();
use Carp               ();
use Data::Dumper       ();
use File::Spec         ();
use File::Basename     ();
use File::Slurp        ();
use List::Util         ();
use Scalar::Util       ();
use Params::Util       ();
use Padre::Util        ();
use Padre::Wx          ();
use Padre::Wx::Editor  ();
use Padre::Wx::ToolBar ();
use Padre::Wx::Output  ();
use Padre::Document    ();
use Padre::Documents   ();
use Padre::Wx::DNDFilesDropTarget ();

use base qw{Wx::Frame};

our $VERSION = '0.19';

my $default_dir = Cwd::cwd();

use constant SECONDS => 1000;

use constant DEFAULT_LOCALE => 'en';

# TODO move it to some better place,
# used in Menu.pm
our %languages = (
	de => Wx::gettext('German'),
	en => Wx::gettext('English'),
	fr => Wx::gettext('French'),
	he => Wx::gettext('Hebrew'),
	hu => Wx::gettext('Hungarian'),
	ko => Wx::gettext('Korean'),
);

my %shortname_of = (
	Wx::wxLANGUAGE_GERMAN()     => 'de',
	Wx::wxLANGUAGE_ENGLISH_US() => 'en',
	Wx::wxLANGUAGE_FRENCH()     => 'fr',
	Wx::wxLANGUAGE_HEBREW()     => 'he',
	Wx::wxLANGUAGE_HUNGARIAN()  => 'hu',
	Wx::wxLANGUAGE_KOREAN()     => 'ko',
);

my %number_of = reverse %shortname_of;





#####################################################################
# Constructor and Accessors

use Class::XSAccessor
	getters => {
		manager        => 'manager',
		no_refresh     => '_no_refresh',
		syntax_checker => 'syntax_checker',
	};


sub new {
	my $class  = shift;

	my $config = Padre->ide->config;
	Wx::InitAllImageHandlers();

	Wx::Log::SetActiveTarget( Wx::LogStderr->new );
	#Wx::LogMessage( 'Start');
	

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
			$title .= Wx::gettext('(running from SVN checkout)');
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
	$self->SetDropTarget(Padre::Wx::DNDFilesDropTarget->new($self));

	$self->set_locale( );

	$self->{manager} = Wx::AuiManager->new;
	$self->{manager}->SetManagedWindow( $self );
	$self->{_methods_} = {};

	# do NOT use hints other than Rectangle or the app will crash on Linux/GTK
	my $flags = $self->{manager}->GetFlags;
	$flags &= ~Wx::wxAUI_MGR_TRANSPARENT_HINT;
	$flags &= ~Wx::wxAUI_MGR_VENETIAN_BLINDS_HINT;
	$self->{manager}->SetFlags( $flags ^ Wx::wxAUI_MGR_RECTANGLE_HINT );

	# Add some additional attribute slots
	$self->{marker} = {};

	$self->{page_history} = [];

	# create basic window components
	$self->create_main_components;

	# Create the main notebook for the documents
	$self->{notebook} = Wx::AuiNotebook->new(
		$self,
		-1,
		Wx::wxDefaultPosition,
		Wx::wxDefaultSize,
		Wx::wxAUI_NB_DEFAULT_STYLE | Wx::wxAUI_NB_WINDOWLIST_BUTTON,
	);
	$self->manager->AddPane(
		$self->{notebook}, 
		Wx::AuiPaneInfo->new->Name( "notebook" )
			->CenterPane->Resizable->PaneBorder->Dockable
			->Caption( Wx::gettext("Files") )->Position( 1 )
	);

	Wx::Event::EVT_AUINOTEBOOK_PAGE_CHANGED(
		$self,
		$self->{notebook},
		sub {
			my $editor = $_[0]->selected_editor;
			if ($editor) {
				@{ $_[0]->{page_history} } = grep {
					Scalar::Util::refaddr($_) ne Scalar::Util::refaddr($editor)
				} @{ $_[0]->{page_history} };
				push @{ $_[0]->{page_history} }, $editor;
			}
			$_[0]->refresh_all;
			},
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
	Wx::Event::EVT_KILL_FOCUS($self->{rightbar}, \&on_rightbar_left );
	$self->manager->AddPane(
		$self->{rightbar}, 
		Wx::AuiPaneInfo->new->Name( "rightbar" )
			->CenterPane->Resizable(1)->PaneBorder(1)->Movable(1)
			->CaptionVisible(1)->CloseButton(1)->DestroyOnClose(0)
			->MaximizeButton(1)->Floatable(1)->Dockable(1)
			->Caption( Wx::gettext("Subs") )->Position( 3 )->Right->Layer(3)
	);
	$self->{rightbar}->InsertColumn(0, Wx::gettext('Methods'));
	$self->{rightbar}->SetColumnWidth(0, Wx::wxLIST_AUTOSIZE);
	Wx::Event::EVT_LIST_ITEM_ACTIVATED(
		$self,
		$self->{rightbar},
		\&on_function_selected,
	);

	# Create the syntax checker and sidebar for syntax check messages
	$self->{syntax_checker} = Padre::Wx::SyntaxChecker->new($self);

	# Create the bottom-of-screen output textarea
	$self->{output} = Padre::Wx::Output->new(
		$self,
	);
	$self->manager->AddPane($self->{output}, 
		Wx::AuiPaneInfo->new->Name( "output" )
			->CenterPane->Resizable(1)->PaneBorder(1)->Movable(1)
			->CaptionVisible(1)->CloseButton(1)->DestroyOnClose(0)
			->MaximizeButton(1)->Floatable(1)->Dockable(1)
			->Caption( Wx::gettext("Output") )->Position(2)->Bottom->Layer(4)
		);

	# on close pane
	Wx::Event::EVT_AUI_PANE_CLOSE(
		$self, \&on_close_pane
	);

	# Special Key Handling
	Wx::Event::EVT_KEY_UP( $self, sub {
		my ($self, $event) = @_;
		my $mod  = $event->GetModifiers || 0;
		my $code = $event->GetKeyCode;
		
		# remove the bit ( Wx::wxMOD_META) set by Num Lock being pressed on Linux
		$mod = $mod & (Wx::wxMOD_ALT() + Wx::wxMOD_CMD() + Wx::wxMOD_SHIFT());
		if ( $mod == Wx::wxMOD_CMD ) { # Ctrl
			# Ctrl-TAB  #TODO it is already in the menu
			$self->on_next_pane if $code == Wx::WXK_TAB;
		} elsif ( $mod == Wx::wxMOD_CMD() + Wx::wxMOD_SHIFT()) { # Ctrl-Shift
			# Ctrl-Shift-TAB #TODO it is already in the menu
			$self->on_prev_pane if $code == Wx::WXK_TAB;
		}
		$event->Skip();
		return;
	} );
	
	# remember the last time we show them or not
	unless ( $self->{menu}->{view_output}->IsChecked ) {
		$self->manager->GetPane('output')->Hide;
	}
	unless ( $self->{menu}->{view_functions}->IsChecked ) {
		$self->manager->GetPane('rightbar')->Hide;
	}

	$self->manager->Update;

	# Deal with someone closing the window
	Wx::Event::EVT_CLOSE(           $self,     \&on_close_window     );
	Wx::Event::EVT_STC_UPDATEUI(    $self, -1, \&on_stc_update_ui    );
	Wx::Event::EVT_STC_CHANGE(      $self, -1, \&on_stc_change       );
	Wx::Event::EVT_STC_STYLENEEDED( $self, -1, \&on_stc_style_needed );
	Wx::Event::EVT_STC_CHARADDED(   $self, -1, \&on_stc_char_added   );
	Wx::Event::EVT_STC_DWELLSTART(  $self, -1, \&on_stc_dwell_start  );

	# As ugly as the WxPerl icon is, the new file toolbar image is uglier
	$self->SetIcon( Wx::GetWxPerlIcon() );

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

	if ( defined $config->{host}->{aui_manager_layout} ) {
		$self->manager->LoadPerspective( $config->{host}->{aui_manager_layout} );
	}

	return $self;
}

sub create_main_components {
	my $self = shift;

	# Create the menu bar
	if ( defined $self->{menu} ) {
		delete $self->{menu};
	}
	$self->{menu} = Padre::Wx::Menu->new( $self );
	$self->SetMenuBar( $self->{menu}->{wx} );

	# Create the tool bar
	$self->SetToolBar( Padre::Wx::ToolBar->new($self) );
	$self->GetToolBar->Realize;

	# Create the status bar
	if ( ! defined $self->{statusbar} ) {
		$self->{statusbar} = $self->CreateStatusBar;
		$self->{statusbar}->SetFieldsCount(4);
		$self->{statusbar}->SetStatusWidths(-1, 100, 50, 100);
	}

	return;
}


# Load any default files
sub load_files {
	my $self   = shift;
	my $config = Padre->ide->config;
	my $files  = Padre->inst->{ARGV};
	if ( Params::Util::_ARRAY($files) ) {
		$self->Freeze;
		foreach my $f ( @$files ) {
		    $self->setup_editor($f);
		}
		$self->Thaw;
	} elsif ( $config->{main_startup} eq 'new' ) {
		$self->Freeze;
		$self->setup_editor;
		$self->Thaw;
	} elsif ( $config->{main_startup} eq 'nothing' ) {
		# nothing
	} elsif ( $config->{main_startup} eq 'last' ) {
		if ( $config->{host}->{main_files} ) {
			$self->Freeze;
			my @main_files     = @{$config->{host}->{main_files}};
			my @main_files_pos = @{$config->{host}->{main_files_pos}};
			foreach my $i ( 0 .. $#main_files ) {
				my $file = $main_files[$i];
				my $id   = $self->setup_editor($file);
				if ( $id and $main_files_pos[$i] ) {
					my $doc  = Padre::Documents->by_id($id);
					$doc->editor->GotoPos( $main_files_pos[$i] );
				}
			}
			if ( $config->{host}->{main_file} ) {
				my $id = $self->find_editor_of_file( $config->{host}->{main_file} );
				$self->on_nth_pane($id) if (defined $id);
			}
			$self->Thaw;
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
	Padre->ide->plugin_manager->enable_editors_for_all;
	$self->refresh_all;

	my $output = $self->{menu}->{view_output}->IsChecked;
	# First we show the output window and then hide it if necessary
	# in order to avoide some weird visual artifacts (empty square at
	# top left part of the whole application)
	# TODO maybe some users want to make sure the output window is always
	# off at startup.
	$self->show_output(1);
	$self->show_output($output) if not $output;

	if ( $self->{menu}->{view_show_syntaxcheck}->IsChecked ) {
		$self->syntax_checker->enable(1);
	}

	# Check for new plugins and alert if so
	my $plugins = Padre->ide->plugin_manager->alert_new;

	# Start the change detection timer
	my $timer = Wx::Timer->new( $self, Padre::Wx::id_FILECHK_TIMER );
	Wx::Event::EVT_TIMER($self, Padre::Wx::id_FILECHK_TIMER, \&on_timer_check_overwrite);
	$timer->Start(5 * SECONDS, 0);

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

sub refresh_all {
	my ($self) = @_;

	return if $self->no_refresh;

	my $doc  = $self->selected_document;
	$self->refresh_menu;
	$self->refresh_toolbar;
	$self->refresh_status;
	$self->refresh_methods;
	$self->refresh_syntaxcheck;
	
	my $id = $self->{notebook}->GetSelection();
	if (defined $id and $id >= 0) {
		$self->{notebook}->GetPage($id)->SetFocus;
	}

	# force update of list of opened files in window menu
	# TODO: shouldn't this be in Padre::Wx::Menu::refresh()?
	if ( defined $self->{menu}->{alt} ) {
		foreach my $i ( 0 .. @{ $self->{menu}->{alt} } - 1 ) {
			my $doc = Padre::Documents->by_id($i) or return;
			my $file = $doc->filename || $self->{notebook}->GetPageText($i);
			$self->{menu}->update_alt_n_menu($file, $i);
		}
	}

	return;
}

sub change_locale {
	my ($self, $shortname) = @_;

	my $config = Padre->ide->config;
	$config->{host}->{locale} = $shortname;

	delete $self->{locale};
	$self->set_locale;

	$self->create_main_components;

	$self->refresh_all;

	$self->manager->GetPane('output')->Caption( Wx::gettext("Output") );
	$self->manager->GetPane('syntaxbar')->Caption( Wx::gettext("Syntax") );
	$self->manager->GetPane('rightbar')->Caption( Wx::gettext("Subs") );
	return;
}

sub shortname {
	my $config    = Padre->ide->config;
	my $shortname = $config->{host}->{locale};
	$shortname ||= 
		$shortname_of{ Wx::Locale::GetSystemLanguage } || DEFAULT_LOCALE ;
	return $shortname;
}
sub set_locale {
	my $self = shift;

	my $shortname = shortname();
	my $lang = $number_of{ $shortname };
	$self->{locale} = Wx::Locale->new($lang);
	$self->{locale}->AddCatalogLookupPathPrefix( Padre::Util::sharedir('locale') );
	my $langname = $self->{locale}->GetCanonicalName();

	#my $shortname = $langname ? substr( $langname, 0, 2 ) : 'en'; # only providing default sublangs
	my $filename = Padre::Util::sharefile( 'locale', $shortname ) . '.mo';

	unless ( $self->{locale}->IsLoaded($shortname) ) {
		$self->{locale}->AddCatalog($shortname) if -f $filename;
	}

	return;
}

sub refresh_syntaxcheck {
	my $self = shift;
	return if $self->no_refresh;
	return if not Padre->ide->config->{experimental};
	return if not $self->{menu}->{view_show_syntaxcheck}->IsChecked;

	Padre::Wx::SyntaxChecker::on_syntax_check_timer( $self, undef, 1 );

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

	my $charWidth = $self->{statusbar}->GetCharWidth;
	my $mt = $doc->get_mimetype;
	my $curPos = Wx::gettext('L:') . ($line + 1) . ' ' . Wx::gettext('Ch:') . $char;

	$self->SetStatusText($mt,           1);
	$self->SetStatusText($newline_type, 2);
	$self->SetStatusText($curPos,       3);

    # since charWidth is an average we adjust the values a little
	$self->{statusbar}->SetStatusWidths(
		-1,
		(length($mt)           - 1) * $charWidth,
		(length($newline_type) + 2) * $charWidth,
		(length($curPos)       + 1) * $charWidth
	); 

	return;
}

# TODO now on every ui chnage (move of the mouse)
# we refresh this even though that should not be
# necessary 
# can that be eliminated ?
sub refresh_methods {
	my ($self) = @_;
	return if $self->no_refresh;
	return unless ( $self->{menu}->{view_functions}->IsChecked );

	my $doc = $self->selected_document;
	if (not $doc) {
		$self->{rightbar}->DeleteAllItems;
		return;
	}

	my %methods = map {$_ => 1} $doc->get_functions;
	my $new = join ';', sort keys %methods;
	my $old = join ';', sort keys %{ $self->{_methods_} };
	return if $old eq $new;
	
	$self->{rightbar}->DeleteAllItems;
	foreach my $method ( sort keys %methods ) {
		$self->{rightbar}->InsertStringItem(0, $method);
	}
	$self->{rightbar}->SetColumnWidth(0, Wx::wxLIST_AUTOSIZE);
	$self->{_methods_} = \%methods;

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

	my $dialog = Padre::Wx::History::TextDialog->new(
		$main_window,
		Wx::gettext("Command line"),
		Wx::gettext("Run setup"),
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

	return $self->error(Wx::gettext("No open document")) if not $document;

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
		return $self->error(Wx::gettext("No execution mode was defined for this document"));
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
		return $self->error(Wx::gettext("Not a Perl document"));
	}

	# Check the file name
	my $filename = $document->filename;
	unless ( $filename =~ /\.pl$/i ) {
		return $self->error(Wx::gettext("Only .pl files can be executed"));
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
	my $title   = shift || Wx::gettext('Message');
	Wx::MessageBox( $message, $title, Wx::wxOK | Wx::wxCENTRE, $self );
	return;
}

sub error {
	my $self = shift;
	$self->message( shift, Wx::gettext('Error') );
}

sub find {
	my $self = shift;

	if ( not defined $self->{fast_find_panel} ) {
		require Padre::Wx::Dialog::Search;
		$self->{fast_find_panel} = Padre::Wx::Dialog::Search->new;
	}

	return $self->{fast_find_panel};
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
	my $begin  = $page->LineFromPosition($page->GetSelectionStart);
	my $end    = $page->LineFromPosition($page->GetSelectionEnd);
	my $doc    = $self->selected_document;

	my $str = $doc->comment_lines_str;
	return if not defined $str;
	$page->comment_lines($begin, $end, $str);

	return;
}

sub on_uncomment_block {
	my ($self, $event) = @_;

	my $pageid = $self->{notebook}->GetSelection();
	my $page   = $self->{notebook}->GetPage($pageid);
	my $begin  = $page->LineFromPosition($page->GetSelectionStart);
	my $end    = $page->LineFromPosition($page->GetSelectionEnd);
	my $doc    = $self->selected_document;

	my $str = $doc->comment_lines_str;
	return if not defined $str;
	$page->uncomment_lines($begin, $end, $str);

	return;
}

sub on_autocompletition {
	my $self   = shift;
	my $doc    = $self->selected_document or return;
	my ( $length, @words ) = $doc->autocomplete;
	if ( $length =~ /\D/ ) {
		Wx::MessageBox($length, Wx::gettext("Autocompletions error"), Wx::wxOK);
	}
	if ( @words ) {
		$doc->editor->AutoCompShow($length, join " ", @words);
	}
	return;
}

sub on_goto {
	my $self = shift;

	my $dialog = Wx::TextEntryDialog->new( $self, Wx::gettext("Line number:"), "", '' );
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
	# Save all Pos for open files
	$config->{host}->{main_files_pos} = [
		map  { $_->editor->GetCurrentPos }
		grep { $_ } 
		map  { Padre::Documents->by_id($_) }
		$self->pageids
	];
	# Save selected tab
	$config->{host}->{main_file} = $self->selected_filename;

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

	$config->{host}->{aui_manager_layout} = $self->manager->SavePerspective;

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

	Padre->ide->plugin_manager->editor_enable($new_editor);

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
	
	my $doc = Padre::Document->new(
		filename => $file,
	);

	my $editor = Padre::Wx::Editor->new( $self->{notebook} );
	$editor->{Document} = $doc;
	$doc->set_editor( $editor );
	$editor->configure_editor($doc);
	
	Padre->ide->plugin_manager->editor_enable($editor);

	my $title = $editor->{Document}->get_title;

	$editor->set_preferences;

	if ( $config->{editor_syntaxcheck} ) {
		if ( $editor->GetMarginWidth(1) == 0 ) {
			$editor->SetMarginType(1, Wx::wxSTC_MARGIN_SYMBOL); # margin number 1 for symbols
			$editor->SetMarginWidth(1, 16);                     # set margin 1 16 px wide
		}
	}

	my $id = $self->create_tab($editor, $file, $title);

	$editor->padre_setup;

	Wx::Event::EVT_MOTION( $editor, \&Padre::Wx::Editor::on_mouse_motion );

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
		Wx::MessageBox(
			Wx::gettext("Need to have something selected"),
			Wx::gettext("Open Selection"),
			Wx::wxOK,
			$self,
		);
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
		Wx::MessageBox(sprintf(Wx::gettext("Could not find file '%s'"), $selection), Wx::gettext("Open Selection"), Wx::wxOK, $self);
		return;
	}

	Padre::DB->add_recent_files($file);
	$self->setup_editor($file);
	$self->refresh_all;

	return;
}

sub on_open_all_recent_files {
	my ( $self ) = @_;
	
	my $files = Padre::DB->get_recent_files;
	foreach my $file ( @$files ) {
		$self->setup_editor($file);
	}
	$self->refresh_all;
}

sub on_open {
	my ($self, $event) = @_;

	my $current_filename = $self->selected_filename;
	if ($current_filename) {
		$default_dir = File::Basename::dirname($current_filename);
	}
	my $dialog = Wx::FileDialog->new(
		$self,
		Wx::gettext("Open file"),
		$default_dir,
		"",
		"*.*",
		Wx::wxFD_MULTIPLE,
	);
	unless ( Padre::Util::WIN32 ) {
		$dialog->SetWildcard("*");
	}
	if ( $dialog->ShowModal == Wx::wxID_CANCEL ) {
		return;
	}
	my @filenames = $dialog->GetFilenames;
	$default_dir = $dialog->GetDirectory;

	# If and only if there is only one current file,
	# and it is unused, close it.
	if ( $self->{notebook}->GetPageCount == 1 ) {
		if ( Padre::Documents->current->is_unused ) {
			$self->on_close($self);
		}
	}

	$self->Freeze;
	foreach my $filename ( @filenames ) {
		my $file = File::Spec->catfile($default_dir, $filename);
		Padre::DB->add_recent_files($file);
		$self->setup_editor($file);
	}
	$self->refresh_all;
	$self->Thaw;

	return;
}

sub on_reload_file {
	my ($self) = @_;

	my $doc     = $self->selected_document or return;
	if (not $doc->reload) {
		$self->error(sprintf(Wx::gettext("Could not reload file: %s"), $doc->errstr));
	} else {
		$doc->editor->configure_editor($doc);
	}

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
			Wx::gettext("Save file as..."),
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
				Wx::gettext("File already exists. Overwrite it?"),
				Wx::gettext("Exist"),
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
	$doc->rebless;

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
			Wx::gettext("File changed on disk since last saved. Do you want to overwrite it?"),
			$doc->filename || Wx::gettext("File not in sync"),
			Wx::wxYES_NO|Wx::wxCENTRE,
			$self,
		);
		return if $ret != Wx::wxYES;
	}

	my $error = $doc->save_file;
	if ($error) {
		Wx::MessageBox($error, Wx::gettext("Error"), Wx::wxOK, $self);
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
			Wx::gettext("File changed. Do you want to save it?"),
			$doc->filename || Wx::gettext("Unsaved File"),
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
	# TODO: shouldn't this be in Padre::Wx::Menu::refresh()?
	# TODO: why don't we call $self->refresh_all()?
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
	$self->refresh_all;
	$self->Thaw;

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
	my $self = shift;
	my $doc  = Padre::Documents->current;
	return if not $doc;

	my $current = $doc->text_get;
	my $file    = $doc->filename;
	return $self->error(Wx::gettext("Cannot diff if file was never saved")) if not $file;

	require Text::Diff;
	my $diff = Text::Diff::diff($file, \$current);
	
	if ( not $diff ) {
		$diff = Wx::gettext("There are no differences\n");
	}
	$self->show_output;
	$self->{output}->clear;
	$self->{output}->AppendText($diff);
	return;
}

#
# on_full_screen()
#
# toggle full screen status.
#
sub on_full_screen {
	my ($self, $event) = @_;
	$self->ShowFullScreen( ! $self->IsFullScreen );
}

#
# on_join_lines()
#
# join current line with next one (a-la vi with Ctrl+J)
#
sub on_join_lines {
	my ($self) = @_;

	my $notebook = $self->{notebook};
	my $id   = $notebook->GetSelection;
	my $page = $notebook->GetPage($id);
	
	# find positions
	my $pos1 = $page->GetCurrentPos;
	my $line = $page->LineFromPosition($pos1);
	my $pos2 = $page->PositionFromLine($line+1);

	# mark target & join lines
	$page->SetTargetStart($pos1);
	$page->SetTargetEnd($pos2);
	$page->LinesJoin;
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

	Padre::Wx::Dialog::Preferences->run( $self );

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

sub on_toggle_code_folding {
	my ($self, $event) = @_;

	my $config = Padre->ide->config;
	$config->{editor_codefolding} = $event->IsChecked ? 1 : 0;

	foreach my $editor ( $self->pages ) {
		$editor->show_folding( $config->{editor_codefolding} );
	}

	return;
}

sub on_toggle_current_line_background {
	my ($self, $event) = @_;

	my $config = Padre->ide->config;
	$config->{editor_currentlinebackground} = $event->IsChecked ? 1 : 0;

	foreach my $editor ( $self->pages ) {
		$editor->show_currentlinebackground( $config->{editor_currentlinebackground} ? 1 : 0 );
	}

	return;
}

sub on_toggle_syntax_check {
	my ($self, $event) = @_;

	my $config = Padre->ide->config;
	$config->{editor_syntaxcheck} = $event->IsChecked ? 1 : 0;

	$self->syntax_checker->enable( $config->{editor_syntaxcheck} ? 1 : 0 );

	$self->{menu}->{window_goto_syntax_check}->Enable( $config->{editor_syntaxcheck} ? 1 : 0 );

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

#
# on_toggle_whitespaces()
#
# show/hide spaces and tabs (with dots and arrows respectively).
#
sub on_toggle_whitespaces {
	my ($self) = @_;
	
	# check whether we need to show / hide spaces & tabs.
	my $config = Padre->ide->config;
	$config->{editor_whitespaces} = $self->{menu}->{view_whitespaces}->IsChecked
		? Wx::wxSTC_WS_VISIBLEALWAYS
		: Wx::wxSTC_WS_INVISIBLE;
	
	# update all open views with the new config.
	foreach my $editor ( $self->pages ) {
		$editor->SetViewWhiteSpace( $config->{editor_whitespaces} );
	}
}


sub on_word_wrap {
	my $self = shift;
	my $on   = @_ ? $_[0] ? 1 : 0 : 1;
	unless ( $on == $self->{menu}->{view_word_wrap}->IsChecked ) {
		$self->{menu}->{view_word_wrap}->Check($on);
	}
	
	my $doc = $self->selected_document;
	return unless $doc;
	
	if ( $on ) {
		$doc->editor->SetWrapMode( Wx::wxSTC_WRAP_WORD );
	} else {
		$doc->editor->SetWrapMode( Wx::wxSTC_WRAP_NONE );
	}
}

sub show_output {
	my $self = shift;
	my $on   = @_ ? $_[0] ? 1 : 0 : 1;
	unless ( $on == $self->{menu}->{view_output}->IsChecked ) {
		$self->{menu}->{view_output}->Check($on);
	}
	if ( $on ) {
		$self->manager->GetPane('output')->Show();
		$self->manager->Update;
	} else {
		$self->manager->GetPane('output')->Hide();
		$self->manager->Update;
	}
	Padre->ide->config->{main_output} = $on;

	return;
}

sub show_functions {
	my $self = shift;
	my $on   = @_ ? $_[0] ? 1 : 0 : 1;
	unless ( $on == $self->{menu}->{view_functions}->IsChecked ) {
		$self->{menu}->{view_functions}->Check($on);
	}
	if ( $on ) {
	    $self->refresh_methods();
		$self->manager->GetPane('rightbar')->Show();
		$self->manager->Update;
	} else {
		$self->manager->GetPane('rightbar')->Hide();
		$self->manager->Update;
	}
	Padre->ide->config->{main_rightbar} = $on;

	return;
}

sub show_syntaxbar {
	my $self = shift;
	my $on   = scalar(@_) ? $_[0] ? 1 : 0 : 1;
	unless ( $self->{menu}->{view_show_syntaxcheck}->IsChecked ) {
		$self->manager->GetPane('syntaxbar')->Hide();
		$self->manager->Update;
		return;
	}
	if ( $on ) {
		$self->manager->GetPane('syntaxbar')->Show();
		$self->manager->Update;
	}
	else {
		$self->manager->GetPane('syntaxbar')->Hide();
		$self->manager->Update;
	}
	return;
}

sub on_ppi_highlight {
	my ($self, $event) = @_;

	my $config = Padre->ide->config;
	$config->{ppi_highlight} = $event->IsChecked ? 1 : 0;
	$Padre::Document::MIME_LEXER{'application/x-perl'} = 
		$config->{ppi_highlight} ? Wx::wxSTC_LEX_CONTAINER : Wx::wxSTC_LEX_PERL;
		
	foreach my $editor ( $self->pages ) {
		#my $editor = $self->selected_editor;
		next if not $editor->{Document}->isa('Padre::Document::Perl');
		if ($config->{ppi_highlight}) {
			$editor->{Document}->colorize;
		} else {
			$editor->{Document}->remove_color;
			$editor->Colourise(0, $editor->GetLength);
		}
	}

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

sub on_insert_from_file {
	my ( $win ) = @_;
	
	my $id  = $win->{notebook}->GetSelection;
	return if $id == -1;
	
	# popup the window
	my $last_filename = $win->selected_filename;
	my $default_dir;
	if ($last_filename) {
		$default_dir = File::Basename::dirname($last_filename);
	}
	my $dialog = Wx::FileDialog->new(
		$win, Wx::gettext('Open file'), $default_dir, '', '*.*', Wx::wxFD_OPEN,
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
    
	my $text = eval { File::Slurp::read_file($file, binmode => ':raw') };
	if ($@) {
		$win->error($@);
		return;
	}
	
	my $data = Wx::TextDataObject->new;
	$data->SetText($text);
	my $length = $data->GetTextLength;
	
	my $editor = $win->{notebook}->GetPage($id);
	$editor->ReplaceSelection('');
	my $pos = $editor->GetCurrentPos;
	$editor->InsertText( $pos, $text );
	$editor->GotoPos( $pos + $length - 1 );
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

	$self->refresh_all;

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
		Wx::MessageBox(sprintf(Wx::gettext("Error: %s"), $@), Wx::gettext("Self error"), Wx::wxOK, $self);
		return;
	}
	return;
}

sub on_function_selected {
	my ($self, $event) = @_;
	my $sub = $event->GetItem->GetText;
	return if not defined $sub;

	my $doc = $self->selected_document;
	Padre::Wx::Dialog::Find->search( search_term => $doc->get_function_regex($sub) );
	$self->selected_editor->SetFocus;
	return;
}


## STC related functions

sub on_stc_style_needed {
	my ( $self, $event ) = @_;

	my $doc = Padre::Documents->current or return;
	if ($doc->can('colorize')) {

		# workaround something that seems like a Scintilla bug
		# when the cursor is close to the end of the document
		# and there is code at the end of the document (and not comment)
		# the STC_STYLE_NEEDED event is being constantly called
		my $text = $doc->text_get;
		return if defined $doc->{_text} and $doc->{_text} eq $text;
		$doc->{_text} = $text;

		$doc->colorize;
	}

}


sub on_stc_update_ui {
	my ($self, $event) = @_;

	# avoid recursion
	return if $self->{_in_stc_update_ui};
	local $self->{_in_stc_update_ui} = 1;

	# check for brace, on current position, higlight the matching brace
	my $editor = $self->selected_editor;
	$editor->highlight_braces;
	$editor->show_calltip;

	$self->refresh_menu;
	$self->refresh_toolbar;
	$self->refresh_status;
	#$self->refresh_methods;
	#$self->refresh_syntaxcheck;
	# avoid refreshing the subs as that takes a lot of time
	# TODO maybe we should refresh it on every 20s hit or so
#	$self->refresh_all;

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

	my $key = $event->GetKey;
	if ($key == 10) { # ENTER
		my $editor = $self->selected_editor;
		$editor->autoindent("indent");
	}
	elsif ($key == 125) { # Closing brace }
		my $editor = $self->selected_editor;
		$editor->autoindent("deindent");
	}
	return;
}

sub on_stc_dwell_start {
	my ($self, $event) = @_;

	print Data::Dumper::Dumper $event;
	my $editor = $self->selected_editor;
	print "dwell: ", $event->GetPosition, "\n";
	#$editor->show_tooltip;
	#print Wx::GetMousePosition, "\n";
	#print Wx::GetMousePositionXY, "\n";

	return;
}

sub on_close_pane {
	my ( $self, $event ) = @_;
	my $pane = $event->GetPane();

	# it's ugly, but it works
	if ( Data::Dumper::Dumper(\$pane) eq 
	     Data::Dumper::Dumper(\$self->manager->GetPane('output')) )
	{
		$self->{menu}->{view_output}->Check(0);
	}
	elsif ( Data::Dumper::Dumper(\$pane) eq
	        Data::Dumper::Dumper(\$self->manager->GetPane('rightbar')) )
	{
		$self->{menu}->{view_functions}->Check(0);
	}
}

sub on_quick_find {
	my $self = shift;
	my $on   = @_ ? $_[0] ? 1 : 0 : 1;
	unless ( $on == $self->{menu}->{experimental_quick_find}->IsChecked ) {
		$self->{menu}->{experimental_quick_find}->Check($on);
	}
	Padre->ide->config->{is_quick_find} = $on;

	return;
}

sub on_doc_stats {
	my ($self, $event) = @_;

	my $doc = $self->selected_document;
	if (not $doc) {
		$self->message( 'No file is open', 'Stats' );
		return;
	}

	my ( $lines, $chars_with_space, $chars_without_space, $words, $is_readonly,
		$filename, $newline_type, $encoding)
		= $doc->stats;

	my $message = <<MESSAGE;
Words: $words
Lines: $lines
Chars without spaces: $chars_without_space
Chars with spaces: $chars_with_space
Newline type: $newline_type
Encoding: $encoding
MESSAGE

	$message .= defined $filename ?
				sprintf("Filename: '%s'\n", $filename) :
				"No filename\n";

	if ($is_readonly) {
		$message .= "File is read-only.\n";
	}
	
	$self->message( $message, 'Stats' );
	return;
}

sub on_tab_and_space {
	my ( $self, $type ) = @_;
	
	my $doc = $self->selected_document;
	if (not $doc) {
		$self->message( 'No file is open' );
		return;
	}

	my $title = $type eq 'Space_to_Tab' ? 'Space to Tab' : 'Tab to Space';
	
	my $dialog = Padre::Wx::History::TextDialog->new(
		$self, 'How many spaces for each tab:', $title, $type,
	);
	if ( $dialog->ShowModal == Wx::wxID_CANCEL ) {
		return;
	}
	my $space_num = $dialog->GetValue;
	$dialog->Destroy;
	unless ( defined $space_num and $space_num =~ /^\d+$/ ) {
		return;
	}
	
	my $src = $self->selected_text;
	my $code = ( $src ) ? $src : $doc->text_get;
	
	return unless ( defined $code and length($code) );
	
	my $to_space = ' ' x $space_num;
	if ( $type eq 'Space_to_Tab' ) {
		$code =~ s/$to_space/\t/isg;
	} else {
		$code =~ s/\t/$to_space/isg;
	}
	
	if ( $src ) {
		my $editor = $self->selected_editor;
		$editor->ReplaceSelection( $code );
	} else {
		$doc->text_set( $code );
	}
}

sub on_delete_ending_space {
	my ( $self ) = @_;
	
	my $doc = $self->selected_document;
	if (not $doc) {
		$self->message( 'No file is open' );
		return;
	}
	
	my $src = $self->selected_text;
	my $code = ( $src ) ? $src : $doc->text_get;
	
	# remove ending space
	$code =~ s/([^\n\S]+)$//mg;
	
	if ( $src ) {
		my $editor = $self->selected_editor;
		$editor->ReplaceSelection( $code );
	} else {
		$doc->text_set( $code );
	}
}

sub on_delete_leading_space {
	my ( $self ) = @_;
	
	my $src = $self->selected_text;
	unless ( $src ) {
		$self->message('No selection');
		return;
	}
	
	my $dialog = Padre::Wx::History::TextDialog->new(
		$self, 'How many leading spaces to delete(1 tab == 4 spaces):',
		'Delete Leading Space', 'fay_delete_leading_space',
	);
	if ( $dialog->ShowModal == Wx::wxID_CANCEL ) {
		return;
	}
	my $space_num = $dialog->GetValue;
	$dialog->Destroy;
	unless ( defined $space_num and $space_num =~ /^\d+$/ ) {
		return;
	}

	my $code = $src;
	my $spaces = ' ' x $space_num;
	my $tab_num = int($space_num/4);
	my $space_num_left = $space_num - 4 * $tab_num;
	my $tabs   = "\t" x $tab_num;
	$tabs .= '' x $space_num_left if ( $space_num_left );
	$code =~ s/^($spaces|$tabs)//mg;
	
	my $editor = $self->selected_editor;
	$editor->ReplaceSelection( $code );
}

# TODO next function
# should be in a class representing the rightbar
sub on_rightbar_left {
	my ($self, $event) = @_;
	my $main  = Padre->ide->wx->main_window;
	if ($main->{rightbar_was_closed}) {
		$main->show_functions(0);
		$main->{rightbar_was_closed} = 0;
	}
	return;
}

#
# on_timer_check_overwrite()
#
# called every 5 seconds to check if file has been overwritten outside of
# padre.
#
sub on_timer_check_overwrite {
	my ($self) = @_;

	my $doc = $self->selected_document;
	return unless $doc && $doc->has_changed_on_disk;
	return if ( $doc->{_already_popup_file_changed} );

	$doc->{_already_popup_file_changed} = 1;
	my $ret = Wx::MessageBox(
		Wx::gettext("File changed on disk since last saved. Do you want to reload it?"),
		$doc->filename || Wx::gettext("File not in sync"),
		Wx::wxYES_NO|Wx::wxCENTRE,
		$self,
	);

	if ( $ret == Wx::wxYES ) {
		if (not $doc->reload) {
			$self->error(sprintf(Wx::gettext("Could not reload file: %s"), $doc->errstr));
		} else {
			$doc->editor->configure_editor($doc);
		}
	} else {
		$doc->{_timestamp} = $doc->time_on_file;
	}
	$doc->{_already_popup_file_changed} = 0;
}

sub on_last_visited_pane {
	my ($self, $event) = @_;

	if (@{ $self->{page_history} } >= 2) {
		@{ $self->{page_history} }[-1, -2] = @{ $_[0]->{page_history} }[-2, -1];
		foreach my $i ($self->pageids) {
			my $editor = $_[0]->{notebook}->GetPage($i);
			if ( Scalar::Util::refaddr($editor) eq Scalar::Util::refaddr($_[0]->{page_history}[-1]) ) {
				$self->{notebook}->SetSelection($i);
				last;
			}
		}
		#$self->refresh_all;
		$self->refresh_status;
		$self->refresh_toolbar;
	}
}
1;

# Copyright 2008 Gabor Szabo.
# LICENSE
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl 5 itself.
