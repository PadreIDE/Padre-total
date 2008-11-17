package Padre::Wx::Menu;

use 5.008;
use strict;
use warnings;
use Params::Util qw{_INSTANCE};

use Padre::Wx        ();
use Padre::Util      ();
use Padre::Documents ();
use Wx::Locale       qw(:default);

our $VERSION = '0.16';





#####################################################################
# Construction and Setup

sub new {
	my $class        = shift;
	my $win          = shift;
	my $ide          = Padre->ide;
	my $config       = $ide->config;
	my $experimental = $config->{experimental};

	# Create the menu object
	my $menu     = bless {}, $class;
	$menu->{win} = $win;

	$menu->{file} = $menu->menu_file( $win );
	$menu->{edit} = $menu->menu_edit( $win );
	$menu->{view} = $menu->menu_view( $win );
	$menu->{perl} = $menu->menu_perl( $win );
	$menu->{run}  = $menu->menu_run(  $win );

	# Create the Plugins menu if there are any plugins
	my $menu_plugin = $menu->menu_plugin( $win );
	$menu->{plugin} = $menu_plugin if $menu_plugin;
	$menu->{window} = $menu->menu_window( $win );
	$menu->{help}   = $menu->menu_help( $win );


	# Create the Experimental menu
	# All the crap that doesn't work, have a home,
	# or should never be seen be real users goes here.
	if ( $experimental ) {
		$menu->{experimental} = $menu->menu_experimental( $win );
	}

	$menu->create_main_menu_bar;

	# Setup menu state from configuration
	$menu->{view_lines}->Check( $config->{editor_linenumbers} ? 1 : 0 );
	$menu->{view_folding}->Check( $config->{editor_codefolding} ? 1 : 0 );
	$menu->{view_currentlinebackground}->Check( $config->{editor_currentlinebackground} ? 1 : 0 );
	$menu->{view_eol}->Check( $config->{editor_eol} ? 1 : 0 );
	$menu->{view_whitespaces}->Check( $config->{editor_whitespaces} ? 1 : 0 );
	unless ( Padre::Util::WIN32 ) {
		$menu->{view_statusbar}->Check( $config->{main_statusbar} ? 1 : 0 );
	}
	$menu->{view_output}->Check( $config->{main_output} ? 1 : 0 );
	$menu->{view_functions}->Check( $config->{main_rightbar} ? 1 : 0 );

	$menu->{view_indentation_guide}->Check( $config->{editor_indentationguides} ? 1 : 0 );
	$menu->{view_show_calltips}->Check( $config->{editor_calltips} ? 1 : 0 );

	return $menu;
}

sub create_main_menu_bar {
	my ( $menu ) = @_;

	my $experimental = Padre->ide->config->{experimental};

	# Create and return the main menu bar
	$menu->{wx} = Wx::MenuBar->new;
	$menu->{wx}->Append( $menu->{file},     gettext("&File")      );
	$menu->{wx}->Append( $menu->{project},  gettext("&Project")   );
	$menu->{wx}->Append( $menu->{edit},     gettext("&Edit")      );
	$menu->{wx}->Append( $menu->{view},     gettext("&View")      );
	#$menu->{wx}->Append( $menu->{perl},     gettext("Perl")       );
	$menu->{wx}->Append( $menu->{run},      gettext("&Run")        );
	$menu->{wx}->Append( $menu->{bookmark}, gettext("&Bookmarks") );
	$menu->{wx}->Append( $menu->{plugin},   gettext("Pl&ugins")   ) if $menu->{plugin};
	$menu->{wx}->Append( $menu->{tools},    gettext("&Tools")    );
	$menu->{wx}->Append( $menu->{window},   gettext("&Window")    );
	$menu->{wx}->Append( $menu->{help},     gettext("&Help")      );
	if ( $experimental ) {
		$menu->{wx}->Append( $menu->{experimental}, gettext("E&xperimental") );
	}
}

# Recursively add plugin menu items from nested array refs
sub add_plugin_menu_items {
	my ($self, $menu_items) = @_;

	my $menu = Wx::Menu->new;
	foreach my $m ( @{$menu_items} ) {
		if (ref $m->[1] eq 'ARRAY') {
			my $submenu = $self->add_plugin_menu_items($m->[1]);
			$menu->Append(-1, $m->[0], $submenu);
		} else {
			Wx::Event::EVT_MENU( $self->win, $menu->Append(-1, $m->[0]), $m->[1] );
		}
	}

	return $menu;
}

sub add_alt_n_menu {
	my ($self, $file, $n) = @_;
	#return if $n > 9;

	$self->{alt}->[$n] = $self->{window}->Append(-1, "");
	Wx::Event::EVT_MENU( $self->win, $self->{alt}->[$n], sub { $_[0]->on_nth_pane($n) } );
	$self->update_alt_n_menu($file, $n);

	return;
}

sub update_alt_n_menu {
	my ($self, $file, $n) = @_;
	my $v = $n + 1;

	# TODO: fix the occassional crash here:
	if (not defined $self->{alt}->[$n]) {
		warn "alt-n $n problem ?";
		return;
	}

	#$self->{alt}->[$n]->SetText("$file\tAlt-$v");
	$self->{alt}->[$n]->SetText($file);

	return;
}

sub remove_alt_n_menu {
	my ($self) = @_;

	$self->{window}->Remove(pop @{ $self->{alt} });

	return;
}

sub win {
	$_[0]->{win};
}





#####################################################################
# Reflowing the Menu

# Temporarily hard-wire this to the appropriate menu
# should be integrated in the refresh sub
sub disable_run {
	my $self = shift;
	
	$self->{run_run_script}->Enable(0);
	$self->{run_run_command}->Enable(0);
	$self->{run_stop}->Enable(1);
	return;
}

sub enable_run {
	my $self = shift;

	$self->{run_run_script}->Enable(1);
	$self->{run_run_command}->Enable(1);
	$self->{run_stop}->Enable(0);
	return;
}

sub refresh {
	my $self     = shift;
	my $document = Padre::Documents->current;

	if ( _INSTANCE($document, 'Padre::Document::Perl') and $self->{wx}->GetMenuLabel(3) ne '&Perl') {
		$self->{wx}->Insert( 3, $self->{perl}, '&Perl' );
	} elsif ( not _INSTANCE($document, 'Padre::Document::Perl') and $self->{wx}->GetMenuLabel(3) eq '&Perl') {
		$self->{wx}->Remove( 3 );
	}
	
	if ( $document ) {
		# check "wrap lines"
		my $mode = $document->editor->GetWrapMode;
		my $is_vwl_checked = $self->{view_word_wrap}->IsChecked;
		if ( $mode eq Wx::wxSTC_WRAP_WORD and not $is_vwl_checked ) {
			$self->{view_word_wrap}->Check(1);
		} elsif ( $mode eq Wx::wxSTC_WRAP_NONE and $is_vwl_checked ) {
			$self->{view_word_wrap}->Check(0);
		}
	}

	return 1;
}

sub menu_file {
	my ( $self, $win ) = @_;
	
	# Create the File menu
	my $menu = Wx::Menu->new;

	# Creating new things
	Wx::Event::EVT_MENU( $win,
		$menu->Append( Wx::wxID_NEW, '' ),
		sub {
			$_[0]->setup_editor;
			return;
		},
	);
	my $menu_file_new = Wx::Menu->new;
	$menu->Append( -1, gettext("New..."), $menu_file_new );
	Wx::Event::EVT_MENU( $win,
		$menu_file_new->Append( -1, gettext('Perl Distribution (Module::Starter)') ),
		sub { Padre::Wx::Dialog::ModuleStart->start(@_) },
	);

	# Opening and closing files
	Wx::Event::EVT_MENU( $win,
		$menu->Append( Wx::wxID_OPEN, '' ),
		sub { $_[0]->on_open },
	);
	Wx::Event::EVT_MENU( $win,
		$menu->Append( -1, gettext("Open Selection\tCtrl-Shift-O") ),
		sub { $_[0]->on_open_selection },
	);
	Wx::Event::EVT_MENU( $win,
		$menu->Append( Wx::wxID_CLOSE,  '' ),
		sub { $_[0]->on_close },
	);
	Wx::Event::EVT_MENU( $win,
		$menu->Append( -1, gettext('Close All') ),
		sub { $_[0]->on_close_all },
	);
	Wx::Event::EVT_MENU( $win,
		$menu->Append( -1, gettext('Close All but Current Document') ),
		sub { $_[0]->on_close_all_but_current },
	);
	Wx::Event::EVT_MENU( $win,
		$menu->Append( -1, gettext('Reload file') ),
		sub { $_[0]->on_reload_file },
	);
	$menu->AppendSeparator;

	# Saving
	Wx::Event::EVT_MENU( $win,
		$menu->Append( Wx::wxID_SAVE, '' ),
		sub { $_[0]->on_save },
	);
	Wx::Event::EVT_MENU( $win,
		$menu->Append( Wx::wxID_SAVEAS, '' ),
		sub { $_[0]->on_save_as },
	);
	Wx::Event::EVT_MENU( $win,
		$menu->Append( -1, gettext('Save All') ),
		sub { $_[0]->on_save_all },
	);
	$menu->AppendSeparator;

	# Conversions and Transforms
	my $menu_file_convert = Wx::Menu->new;
	$menu->Append( -1, gettext("Convert..."), $menu_file_convert );
	Wx::Event::EVT_MENU( $win,
		$menu_file_convert->Append(-1, gettext("EOL to Windows")),
		sub { $_[0]->convert_to("WIN") },
	);
	Wx::Event::EVT_MENU( $win,
		$menu_file_convert->Append(-1, gettext("EOL to Unix")),
		sub { $_[0]->convert_to("UNIX") },
	);
	Wx::Event::EVT_MENU( $win,
		$menu_file_convert->Append(-1, gettext("EOL to Mac Classic")),
		sub { $_[0]->convert_to("MAC") },
	);
	$menu->AppendSeparator;

	# Recent things
	$self->{file_recentfiles} = Wx::Menu->new;
	$menu->Append( -1, gettext("Recent Files"), $self->{file_recentfiles} );
	Wx::Event::EVT_MENU( $win,
		$self->{file_recentfiles}->Append(-1, gettext("Open All Recent Files")),
		sub { $_[0]->on_open_all_recent_files },
	);
	Wx::Event::EVT_MENU( $win,
		$self->{file_recentfiles}->Append(-1, gettext("Clean Recent Files List")),
		sub {
			Padre::DB->delete_recent( 'files' );
			# replace the whole File menu
			my $menu = $_[0]->{menu}->menu_file($_[0]);
			my $menu_place = $_[0]->{menu}->{wx}->FindMenu( gettext("&File") );
			$_[0]->{menu}->{wx}->Replace( $menu_place, $menu, gettext("&File") );
		},
	);
	$self->{file_recentfiles}->AppendSeparator;
	foreach my $f ( Padre::DB->get_recent_files ) {
		next unless -f $f;
		Wx::Event::EVT_MENU( $win,
			$self->{file_recentfiles}->Append(-1, $f), 
            sub { 
                if ( $_[ 0 ]->{notebook}->GetPageCount == 1 ) {
                    if ( Padre::Documents->current->is_unused ) {
                        $_[0]->on_close;
                    }
                }
                $_[0]->setup_editor($f);
				$_[0]->refresh_all;
            },
		);
	}
	$menu->AppendSeparator;
	
	# Word Stats
	Wx::Event::EVT_MENU( $win,
		$menu->Append( -1, gettext('Doc Stats') ),
		sub { $_[0]->on_doc_stats },
	);
	$menu->AppendSeparator;

	# Exiting
	Wx::Event::EVT_MENU( $win,
		$menu->Append( Wx::wxID_EXIT, '' ),
		sub { $_[0]->Close },
	);
	
	return $menu;
}

sub menu_edit {
	my ( $self, $win ) = @_;
	
	# Create the Edit menu
	my $menu = Wx::Menu->new;

	# Undo/Redo
	Wx::Event::EVT_MENU( $win, # Ctrl-Z
		$menu->Append( Wx::wxID_UNDO, '' ),
		sub {
			my $editor = Padre::Documents->current->editor;
			if ( $editor->CanUndo ) {
				$editor->Undo;
			}
			return;
		},
	);
	Wx::Event::EVT_MENU( $win, # Ctrl-Y
		$menu->Append( Wx::wxID_REDO, '' ),
		sub {
			my $editor = Padre::Documents->current->editor;
			if ( $editor->CanRedo ) {
				$editor->Redo;
			}
			return;
		},
	);
	$menu->AppendSeparator;

	my $menu_edit_select = Wx::Menu->new;
	$menu->Append( -1, gettext("Select"), $menu_edit_select );
	Wx::Event::EVT_MENU( $win,
		$menu_edit_select->Append( Wx::wxID_SELECTALL, gettext("Select all\tCtrl-A") ),
		sub { \&Padre::Wx::Editor::text_select_all(@_) },
	);
	$menu_edit_select->AppendSeparator;
	Wx::Event::EVT_MENU( $win,
		$menu_edit_select->Append( -1, gettext("Mark selection start\tCtrl-[") ),
		\&Padre::Wx::Editor::text_selection_mark_start,
	);
	Wx::Event::EVT_MENU( $win,
		$menu_edit_select->Append( -1, gettext("Mark selection end\tCtrl-]") ),
		\&Padre::Wx::Editor::text_selection_mark_end,
	);
	Wx::Event::EVT_MENU( $win,
		$menu_edit_select->Append( -1, gettext("Clear selection marks") ),
		\&Padre::Wx::Editor::text_selection_clear_marks,
	);


    
    Wx::Event::EVT_MENU( $win,
        $menu->Append( Wx::wxID_COPY, '' ),
        sub { Padre::Wx::Editor::text_copy_to_clipboard() },
    );
    Wx::Event::EVT_MENU( $win,
        $menu->Append( Wx::wxID_CUT, '' ),
        sub { Padre::Wx::Editor::text_cut_to_clipboard() },
    );
    Wx::Event::EVT_MENU( $win,
        $menu->Append( Wx::wxID_PASTE, '' ),
        sub { Padre::Wx::Editor::text_paste_from_clipboard() },
    );
    $menu->AppendSeparator;

	Wx::Event::EVT_MENU( $win,
		$menu->Append( Wx::wxID_FIND, '' ),
		sub { Padre::Wx::Dialog::Find->find(@_) },
	);
	Wx::Event::EVT_MENU( $win,
		$menu->Append( -1, gettext("&Find Next\tF3") ),
		sub { Padre::Wx::Dialog::Find->find_next(@_) },
	);
	Wx::Event::EVT_MENU( $win,
		$menu->Append( -1, gettext("Find Previous\tShift-F3") ),
		sub { Padre::Wx::Dialog::Find->find_previous(@_) },
	);
	Wx::Event::EVT_MENU( $win,
		$menu->Append( -1, gettext("Ac&k") ),
		\&Padre::Wx::Ack::on_ack,
	);
	Wx::Event::EVT_MENU( $win,
		$menu->Append( -1, gettext("&Goto\tCtrl-G") ),
		\&Padre::Wx::MainWindow::on_goto,
	);
	Wx::Event::EVT_MENU( $win,
		$menu->Append( -1, gettext("&AutoComp\tCtrl-P") ),
		\&Padre::Wx::MainWindow::on_autocompletition,
	);
	Wx::Event::EVT_MENU( $win,
		$menu->Append( -1, gettext("&Brace matching\tCtrl-1") ),
		\&Padre::Wx::MainWindow::on_brace_matching,
	);
	Wx::Event::EVT_MENU( $win,
		$menu->Append( -1, gettext("&Join lines\tCtrl-J") ),
		\&Padre::Wx::MainWindow::on_join_lines,
	);
	$menu->AppendSeparator;

	# Commenting
	Wx::Event::EVT_MENU( $win,
		$menu->Append( -1, gettext("&Comment Selected Lines\tCtrl-M") ),
		\&Padre::Wx::MainWindow::on_comment_out_block,
	);
	Wx::Event::EVT_MENU( $win,
		$menu->Append( -1, gettext("&Uncomment Selected Lines\tCtrl-Shift-M") ),
		\&Padre::Wx::MainWindow::on_uncomment_block,
	);
	$menu->AppendSeparator;

	# Tab And Space
	my $menu_edit_tab = Wx::Menu->new;
	$menu->Append( -1, gettext("Tabs and Spaces"), $menu_edit_tab );
	Wx::Event::EVT_MENU( $win,
		$menu_edit_tab->Append( -1, gettext("Tabs to Spaces...") ),
		sub { $_[0]->on_tab_and_space('Tab_to_Space') },
	);
	Wx::Event::EVT_MENU( $win,
		$menu_edit_tab->Append( -1, gettext("Spaces to Tabs...") ),
		sub { $_[0]->on_tab_and_space('Space_to_Tab') },
	);
	Wx::Event::EVT_MENU( $win,
		$menu_edit_tab->Append( -1, gettext("Delete Trailing Spaces") ),
		sub { $_[0]->on_delete_ending_space() },
	);
	Wx::Event::EVT_MENU( $win,
		$menu_edit_tab->Append( -1, gettext("Delete Leading Spaces") ),
		sub { $_[0]->on_delete_leading_space() },
	);

	# Upper and Lower Case
	my $menu_edit_case = Wx::Menu->new;
	$menu->Append( -1, gettext("Upper/Lower Case"), $menu_edit_case );
	Wx::Event::EVT_MENU( $win,
		$menu_edit_case->Append( -1, gettext("Upper All") ),
		sub { $_[0]->on_upper_and_lower('Upper_All') },
	);
	Wx::Event::EVT_MENU( $win,
		$menu_edit_case->Append( -1, gettext("Lower All") ),
		sub { $_[0]->on_upper_and_lower('Lower_All') },
	);
	Wx::Event::EVT_MENU( $win,
		$menu_edit_case->Append( -1, gettext("Upper First") ),
		sub { $_[0]->on_upper_and_lower('Upper_First') },
	);
	Wx::Event::EVT_MENU( $win,
		$menu_edit_case->Append( -1, gettext("Lower First") ),
		sub { $_[0]->on_upper_and_lower('Lower_First') },
	);
	$menu->AppendSeparator;

	# Diff
	Wx::Event::EVT_MENU( $win,
		$menu->Append( -1, gettext("Diff") ),
		\&Padre::Wx::MainWindow::on_diff,
	);
	Wx::Event::EVT_MENU( $win,
		$menu->Append( -1, gettext("Insert From File...") ),
		\&Padre::Wx::MainWindow::on_insert_from_file,
	);
	$menu->AppendSeparator;

	# User Preferences
	Wx::Event::EVT_MENU( $win,
		$menu->Append( -1, gettext("&Preferences") ),
		\&Padre::Wx::MainWindow::on_preferences,
	);
	
	return $menu;
}

sub menu_view {
	my ( $menu, $win ) = @_;
	
	my $config = Padre->ide->config;
	
	# Create the View menu
	my $menu_view = Wx::Menu->new;

	# GUI Elements
	$menu->{view_output} = $menu_view->AppendCheckItem( -1, gettext("Show Output") );
	Wx::Event::EVT_MENU( $win,
		$menu->{view_output},
		sub {
			$_[0]->show_output(
				$_[0]->{menu}->{view_output}->IsChecked
			),
		},
	);
	$menu->{view_functions} = $menu_view->AppendCheckItem( -1, gettext("Show Functions") );
	Wx::Event::EVT_MENU( $win,
		$menu->{view_functions},
		sub {
			$_[0]->show_functions(
				$_[0]->{menu}->{view_functions}->IsChecked
			),
		},
	);
	unless ( Padre::Util::WIN32 ) {
		# On Windows disabling the status bar is broken, so don't allow it
		$menu->{view_statusbar} = $menu_view->AppendCheckItem( -1, gettext("Show StatusBar") );
		Wx::Event::EVT_MENU( $win,
			$menu->{view_statusbar},
			\&Padre::Wx::MainWindow::on_toggle_status_bar,
		);
	}
	$menu_view->AppendSeparator;

	# Editor look and feel
	$menu->{view_lines} = $menu_view->AppendCheckItem( -1, gettext("Show Line numbers") );
	Wx::Event::EVT_MENU( $win,
		$menu->{view_lines},
		\&Padre::Wx::MainWindow::on_toggle_line_numbers,
	);
	$menu->{view_folding} = $menu_view->AppendCheckItem( -1, gettext("Show Code Folding") );
	Wx::Event::EVT_MENU( $win,
		$menu->{view_folding},
		\&Padre::Wx::MainWindow::on_toggle_code_folding,
	);
	$menu->{view_currentlinebackground} = $menu_view->AppendCheckItem( -1, gettext("Highlight Current Line") );
	Wx::Event::EVT_MENU( $win,
		$menu->{view_currentlinebackground},
		\&Padre::Wx::MainWindow::on_toggle_current_line_background,
	);
	$menu->{view_syntaxcheck} = $menu_view->AppendCheckItem( -1, gettext("Show Syntax Check") );
	Wx::Event::EVT_MENU( $win,
		$menu->{view_syntaxcheck},
		\&Padre::Wx::MainWindow::on_toggle_synchk,
	);
	$menu->{view_eol} = $menu_view->AppendCheckItem( -1, gettext("Show Newlines") );
	Wx::Event::EVT_MENU( $win,
		$menu->{view_eol},
		\&Padre::Wx::MainWindow::on_toggle_eol,
	);
	$menu->{view_whitespaces} = $menu_view->AppendCheckItem( -1, gettext("Show Whitespaces") );
	Wx::Event::EVT_MENU( $win,
		$menu->{view_whitespaces},
		\&Padre::Wx::MainWindow::on_toggle_whitespaces,
	);

	$menu->{view_indentation_guide} = $menu_view->AppendCheckItem( -1, gettext("Show Indentation Guide") );
	Wx::Event::EVT_MENU( $win,
		$menu->{view_indentation_guide},
		\&Padre::Wx::MainWindow::on_toggle_indentation_guide,
	);
	$menu->{view_show_calltips} = $menu_view->AppendCheckItem( -1, gettext("Show Call Tips") );
	Wx::Event::EVT_MENU( $win,
		$menu->{view_show_calltips},
		sub { $config->{editor_calltips} = $menu->{view_show_calltips}->IsChecked },
	);
	$menu_view->AppendSeparator;
	
	$menu->{view_word_wrap} = $menu_view->AppendCheckItem( -1, gettext("Word-Wrap") );
	Wx::Event::EVT_MENU( $win,
		$menu->{view_word_wrap},
		sub {
			$_[0]->on_word_wrap(
				$_[0]->{menu}->{view_word_wrap}->IsChecked
			),
		},
	);
	$menu_view->AppendSeparator;

	Wx::Event::EVT_MENU( $win,
		$menu_view->Append( -1, gettext("Increase Font Size\tCtrl-+") ),
		sub { $_[0]->zoom(+1) },
	);
	Wx::Event::EVT_MENU( $win,
		$menu_view->Append( -1, gettext("Decrease Font Size\tCtrl--") ),
		sub { $_[0]->zoom(-1) },
	);
	Wx::Event::EVT_MENU( $win,
		$menu_view->Append( -1, gettext("Reset Font Size\tCtrl-/") ),
		sub { $_[0]->zoom( -1 * $_[0]->selected_editor->GetZoom ) },
	);

	$menu_view->AppendSeparator;
	Wx::Event::EVT_MENU( $win,
		$menu_view->Append( -1, gettext("Set Bookmark\tCtrl-B") ),
		sub { Padre::Wx::Dialog::Bookmarks->set_bookmark($_[0]) },
	);
	Wx::Event::EVT_MENU( $win,
		$menu_view->Append( -1, gettext("Goto Bookmark\tCtrl-Shift-B") ),
		sub { Padre::Wx::Dialog::Bookmarks->goto_bookmark($_[0]) },
	);

	$menu_view->AppendSeparator;
	$menu->{view_language} = Wx::Menu->new;
	$menu_view->Append( -1, gettext("Language"), $menu->{view_language} );
	
	# TODO horrible, fix this
	if ($config->{host}->{locale} eq 'en') {
		Wx::Event::EVT_MENU( $win,
			$menu->{view_language}->AppendRadioItem( -1, gettext("English") ),
			sub { $_[0]->change_locale('en') },
		);
		Wx::Event::EVT_MENU( $win,
			$menu->{view_language}->AppendRadioItem( -1, gettext("German") ),
			sub { $_[0]->change_locale('de') },
		);
	} else {
		Wx::Event::EVT_MENU( $win,
			$menu->{view_language}->AppendRadioItem( -1, gettext("German") ),
			sub { $_[0]->change_locale('de') },
		);
		Wx::Event::EVT_MENU( $win,
			$menu->{view_language}->AppendRadioItem( -1, gettext("English") ),
			sub { $_[0]->change_locale('en') },
		);
	}

	$menu_view->AppendSeparator;
	Wx::Event::EVT_MENU( $win,
		$menu_view->Append( -1, gettext("&Full screen\tF11") ),
		\&Padre::Wx::MainWindow::on_full_screen,
	);
	
	return $menu_view;
}

sub menu_perl {
	my ( $self, $win ) = @_;
	
	# Create the Perl menu
	my $menu = Wx::Menu->new;

	# Perl-Specific Searches
	my $menu_perl_find_unmatched = $menu->Append( -1, gettext("Find Unmatched Brace") );
	Wx::Event::EVT_MENU( $win,
		$menu_perl_find_unmatched,
		sub {
			my $doc = Padre::Documents->current;
			unless ( $doc and $doc->isa('Padre::Document::Perl') ) {
				return;
			}
			Class::Autouse->load('Padre::PPI');
			my $ppi   = $doc->ppi_get or return;
			my $where = $ppi->find( \&Padre::PPI::find_unmatched_brace );
			if ( $where ) {
				@$where = sort {
					Padre::PPI::element_depth($b) <=> Padre::PPI::element_depth($a)
					or
					$a->location->[0] <=> $b->location->[0]
					or
					$a->location->[1] <=> $b->location->[1]
				} @$where;
				$doc->ppi_select( $where->[0] );
			} else {
				Wx::MessageBox( gettext("All braces appear to be matched"), gettext("Check Complete"), Wx::wxOK, $win );
			}
		},
	);
	
	return $menu;
}

sub menu_run {
	my ( $menu, $win ) = @_;
	
	# Create the Run menu
	my $menu_run = Wx::Menu->new;

	# Script Execution
	$menu->{run_run_script} = $menu_run->Append( -1, gettext("Run Script\tF5") );
	Wx::Event::EVT_MENU( $win,
		$menu->{run_run_script},
		sub { $_[0]->run_script },
	);
	$menu->{run_run_command} = $menu_run->Append( -1, gettext("Run Command\tCtrl-F5") );
	Wx::Event::EVT_MENU( $win,
		$menu->{run_run_command},
		sub { $_[0]->on_run_command },
	);
	$menu->{run_stop} = $menu_run->Append( -1, gettext("&Stop") );
	Wx::Event::EVT_MENU( $win,
		$menu->{run_stop},
		sub {
			if ( $_[0]->{command} ) {
				$_[0]->{command}->TerminateProcess;
			}
			delete $_[0]->{command};
			return;
		},
	);
	$menu->{run_stop}->Enable(0);
	
	return $menu_run;
}

sub menu_plugin {
	my ( $self, $win ) = @_;

	# Get the list of plugins
	my %plugins = %{ Padre->ide->plugin_manager->plugins };
	my @plugins = grep { $_ ne 'MY' } sort keys %plugins or return;
	return unless @plugins;

	# Create the plugin menu
	my $menu = Wx::Menu->new;

	# Add the Plugin Tools menu
	my $tools = $self->menu_plugin_tools( $win );
	$menu->Append( -1, 'Plugin Tools', $tools );
	$menu->AppendSeparator;

	foreach my $name ( 'MY', @plugins ) {
		next if not $plugins{$name};
		my @menu = eval { $plugins{$name}->menu };
		if ( $@ ) {
			warn "Error when calling menu for plugin '$name' $@";
			next;
		}
		my $items = $self->add_plugin_menu_items(\@menu);
		my $label = '';
		if ( $plugins{$name} and $plugins{$name}->can('menu_name') ) {
			$label = $plugins{$name}->menu_name;
		} else {
			$label = $name;
			$label =~ s/::/ /;
		}
		$menu->Append( -1, $label, $items );
		if ( $name eq 'MY' ) {
			$menu->AppendSeparator;
		}
	}
	
	return $menu;
}

sub menu_plugin_tools {
	my ( $self, $win ) = @_;
	
	# Create the tools menu
	my $menu = Wx::Menu->new;
	Wx::Event::EVT_MENU( $win,
		$menu->Append( -1, gettext("Edit My Plugin") ),
		sub  {
			my $self = shift;
			my $file = File::Spec->catfile( Padre->ide->config_dir, 'plugins', 'Padre', 'Plugin', 'MY.pm' );
			if (not -e $file) {
				return $self->error(gettext("Could not find the Padre::Plugin::MY plugin"));
			}
			
			$self->setup_editor($file);
			$self->refresh_all;
		},
	);
	Wx::Event::EVT_MENU( $win,
		$menu->Append( -1, gettext("Reload My Plugin") ),
		sub { Padre::PluginManager::reload_plugin( $_[0], 'MY') },
	);
	$menu->AppendSeparator;

	Wx::Event::EVT_MENU( $win,
		$menu->Append( -1, gettext("Reload All Plugins") ),
		\&Padre::PluginManager::reload_plugins,
	);
	Wx::Event::EVT_MENU( $win,
		$menu->Append( -1, gettext("Test A Plugin From Local Dir") ),
		\&Padre::PluginManager::test_a_plugin,
	);
	
	return $menu;
}

sub menu_window {
	my ( $self, $win ) = @_;
	
	# Create the window menu
	my $menu = Wx::Menu->new;
	Wx::Event::EVT_MENU( $win,
		$menu->Append( -1, gettext("&Split window") ),
		\&Padre::Wx::MainWindow::on_split_window,
	);
	$menu->AppendSeparator;
	Wx::Event::EVT_MENU( $win,
		$menu->Append(-1, gettext("Next File\tCtrl-TAB")),
		\&Padre::Wx::MainWindow::on_next_pane,
	);
	Wx::Event::EVT_MENU( $win,
		$menu->Append(-1, gettext("Previous File\tCtrl-Shift-TAB")),
		\&Padre::Wx::MainWindow::on_prev_pane,
	);
	$menu->AppendSeparator;


	Wx::Event::EVT_MENU( $win,
		$menu->Append( -1, gettext("GoTo Subs Window\tAlt-S") ),
		sub {
			$_[0]->{rightbar_was_closed} = ! Padre->ide->config->{main_rightbar};
			$_[0]->show_functions(1); 
			$_[0]->{rightbar}->SetFocus;
		},
	); 
	Wx::Event::EVT_MENU( $win,
		$menu->Append( -1, gettext("GoTo Output Window\tAlt-O") ),
		sub {
			$_[0]->show_output(1);
			$_[0]->{output}->SetFocus;
		},
	);
	$self->{window_goto_synchk} = $menu->Append( -1, gettext("GoTo Syntax Check Window\tAlt-C") );
	Wx::Event::EVT_MENU( $win,
		$self->{window_goto_synchk},
		sub {
			$_[0]->show_syntaxbar(1);
			$_[0]->{syntaxbar}->SetFocus;
		},
	);
	unless ( $_[0]->{view_syntaxcheck}->IsChecked ) {
		$self->{window_goto_synchk}->Enable(0);
	}
	Wx::Event::EVT_MENU( $win,
		$menu->Append( -1, gettext("GoTo Main Window\tAlt-M") ),
		sub {
			$_[0]->selected_editor->SetFocus;
		},
	); 
	$menu->AppendSeparator;
	
	return $menu;
}

sub menu_help {
	my ( $self, $win ) = @_;
	
	# Create the help menu
	my $menu = Wx::Menu->new;
	my $help = Padre::Wx::Menu::Help->new;

	Wx::Event::EVT_MENU( $win,
		$menu->Append( Wx::wxID_HELP, '' ),
		sub { $help->help($win) },
	);
	Wx::Event::EVT_MENU( $win,
		$menu->Append( -1, gettext("Context Help\tCtrl-Shift-H") ),
		sub {
			my $main      = shift;
			my $selection = $main->selected_text;
			$help->help($main);
			if ( $selection ) {
				$main->{help}->show( $selection );
			}
			return;
		},
	);
	$menu->AppendSeparator;
	Wx::Event::EVT_MENU( $win,
		$menu->Append( Wx::wxID_ABOUT, '' ),
		sub { $help->about },
	);
	
	return $menu;
}

sub menu_experimental {
	my ( $menu, $win ) = @_;
	
	my $config = Padre->ide->config;
	
	my $menu_exp = Wx::Menu->new;
	Wx::Event::EVT_MENU( $win,
		$menu_exp->Append( -1, gettext('Reflow Menu/Toolbar') ),
		sub {
			$DB::single = 1;
			my $document = Padre::Documents->current;
			$_[0]->{menu}->refresh( $document );
			$_[0]->SetMenuBar( $_[0]->{menu}->{wx} );
			$_[0]->GetToolBar->refresh( $document );
			return;
		},
	);
	
	$menu->{experimental_recent_projects} = Wx::Menu->new;
	$menu_exp->Append( -1, gettext("Recent Projects"), $menu->{file_recent_projects} );
	
	Wx::Event::EVT_MENU(
		$win,
		$menu_exp->Append( -1, gettext('Run in &Padre') ),
		sub {
			my $self = shift;
			my $code = Padre::Documents->current->text_get;
			eval $code;
			if ($@) {
				Wx::MessageBox(gettext("Error: ") . "$@", gettext("Self error"), Wx::wxOK, $self);
				return;
			}
			return;
		},
	);
	$menu->{experimental_ppi_syntax_check} = $menu_exp->AppendCheckItem( -1, gettext("Use PPI for Perl5 syntax checking") );
	Wx::Event::EVT_MENU( $win,
		$menu->{experimental_ppi_syntax_check},
		sub {Padre->ide->config->{ppi_syntax_check}
			= $_[0]->{menu}->{experimental_ppi_syntax_check}->IsChecked ? 1 : 0; },
	);
	$menu->{experimental_ppi_syntax_check}->Check( $config->{ppi_syntax_check} ? 1 : 0 );
	
	$menu->{experimental_ppi_highlight} = $menu_exp->AppendCheckItem( -1, gettext("Use PPI for Perl5 syntax highlighting") );
	Wx::Event::EVT_MENU( $win,
		$menu->{experimental_ppi_highlight},
		\&Padre::Wx::MainWindow::on_ppi_highlight,
	);
	$menu->{experimental_ppi_highlight}->Check( $config->{ppi_highlight} ? 1 : 0 );
	$Padre::Document::MIME_LEXER{'application/x-perl'} = 
		$config->{ppi_highlight} ? Wx::wxSTC_LEX_CONTAINER : Wx::wxSTC_LEX_PERL;

	# Quick Find: Press F3 to start search with selected text
	$menu->{experimental_quick_find} = $menu_exp->AppendCheckItem( -1, gettext("Quick Find") );
	Wx::Event::EVT_MENU( $win,
		$menu->{experimental_quick_find},
		sub {
			$_[0]->on_quick_find(
				$_[0]->{menu}->{experimental_quick_find}->IsChecked
			),
		},
	);
	$menu->{experimental_quick_find}->Check( $config->{is_quick_find} ? 1 : 0 );


	$menu->{experimental_vi_mode} = $menu_exp->AppendCheckItem( -1, gettext("vi mode") );
	Wx::Event::EVT_MENU( $win,
		$menu->{experimental_vi_mode},
		sub {
			$_[0]->on_set_vi_mode(
				$_[0]->{menu}->{experimental_vi_mode}->IsChecked
			),
		},
	);
	$menu->{experimental_vi_mode}->Check( $config->{vi_mode} ? 1 : 0 );
	
	return $menu_exp;
}

1;

# Copyright 2008 Gabor Szabo.
# LICENSE
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl 5 itself.
