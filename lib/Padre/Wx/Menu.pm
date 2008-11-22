package Padre::Wx::Menu;

use 5.008;
use strict;
use warnings;
use Params::Util     qw{_INSTANCE};
use Padre::Util      ();
use Padre::Wx        ();
use Padre::Documents ();

our $VERSION = '0.17';





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
	$menu->{plugin} = $menu_plugin;
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
	$menu->{wx}->Append( $menu->{file},     Wx::gettext("&File")      );
	$menu->{wx}->Append( $menu->{project},  Wx::gettext("&Project")   );
	$menu->{wx}->Append( $menu->{edit},     Wx::gettext("&Edit")      );
	$menu->{wx}->Append( $menu->{view},     Wx::gettext("&View")      );
	#$menu->{wx}->Append( $menu->{perl},     Wx::gettext("Perl")       );
	$menu->{wx}->Append( $menu->{run},      Wx::gettext("&Run")        );
	$menu->{wx}->Append( $menu->{bookmark}, Wx::gettext("&Bookmarks") );
	$menu->{wx}->Append( $menu->{plugin},   Wx::gettext("Pl&ugins")   ) if $menu->{plugin};
	$menu->{wx}->Append( $menu->{tools},    Wx::gettext("&Tools")    );
	$menu->{wx}->Append( $menu->{window},   Wx::gettext("&Window")    );
	$menu->{wx}->Append( $menu->{help},     Wx::gettext("&Help")      );
	if ( $experimental ) {
		$menu->{wx}->Append( $menu->{experimental}, Wx::gettext("E&xperimental") );
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
		$self->{file_close}->Enable(1);
	} else {
		$self->{file_close}->Enable(0);
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
			$_[0]->refresh_all;
			return;
		},
	);
	my $menu_file_new = Wx::Menu->new;
	$menu->Append( -1, Wx::gettext("New..."), $menu_file_new );
	Wx::Event::EVT_MENU( $win,
		$menu_file_new->Append( -1, Wx::gettext('Perl Distribution (Module::Starter)') ),
		sub { Padre::Wx::Dialog::ModuleStart->start(@_) },
	);

	# Opening and closing files
	Wx::Event::EVT_MENU( $win,
		$menu->Append( Wx::wxID_OPEN, '' ),
		sub { $_[0]->on_open },
	);
	Wx::Event::EVT_MENU( $win,
		$menu->Append( -1, Wx::gettext("Open Selection\tCtrl-Shift-O") ),
		sub { $_[0]->on_open_selection },
	);
	
	$self->{file_close} = $menu->Append( Wx::wxID_CLOSE,  '' );
	Wx::Event::EVT_MENU( $win,
		$self->{file_close},
		sub { $_[0]->on_close },
	);
	
	Wx::Event::EVT_MENU( $win,
		$menu->Append( -1, Wx::gettext('Close All') ),
		sub { $_[0]->on_close_all },
	);
	Wx::Event::EVT_MENU( $win,
		$menu->Append( -1, Wx::gettext('Close All but Current Document') ),
		sub { $_[0]->on_close_all_but_current },
	);
	Wx::Event::EVT_MENU( $win,
		$menu->Append( -1, Wx::gettext('Reload file') ),
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
		$menu->Append( -1, Wx::gettext('Save All') ),
		sub { $_[0]->on_save_all },
	);
	$menu->AppendSeparator;

	# Conversions and Transforms
	my $menu_file_convert = Wx::Menu->new;
	$menu->Append( -1, Wx::gettext("Convert..."), $menu_file_convert );
	Wx::Event::EVT_MENU( $win,
		$menu_file_convert->Append(-1, Wx::gettext("EOL to Windows")),
		sub { $_[0]->convert_to("WIN") },
	);
	Wx::Event::EVT_MENU( $win,
		$menu_file_convert->Append(-1, Wx::gettext("EOL to Unix")),
		sub { $_[0]->convert_to("UNIX") },
	);
	Wx::Event::EVT_MENU( $win,
		$menu_file_convert->Append(-1, Wx::gettext("EOL to Mac Classic")),
		sub { $_[0]->convert_to("MAC") },
	);
	$menu->AppendSeparator;

	# Recent things
	$self->{file_recentfiles} = Wx::Menu->new;
	$menu->Append( -1, Wx::gettext("Recent Files"), $self->{file_recentfiles} );
	Wx::Event::EVT_MENU( $win,
		$self->{file_recentfiles}->Append(-1, Wx::gettext("Open All Recent Files")),
		sub { $_[0]->on_open_all_recent_files },
	);
	Wx::Event::EVT_MENU( $win,
		$self->{file_recentfiles}->Append(-1, Wx::gettext("Clean Recent Files List")),
		sub {
			Padre::DB->delete_recent( 'files' );
			# replace the whole File menu
			my $menu = $_[0]->{menu}->menu_file($_[0]);
			my $menu_place = $_[0]->{menu}->{wx}->FindMenu( Wx::gettext("&File") );
			$_[0]->{menu}->{wx}->Replace( $menu_place, $menu, Wx::gettext("&File") );
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
		$menu->Append( -1, Wx::gettext('Doc Stats') ),
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
	$menu->Append( -1, Wx::gettext("Select"), $menu_edit_select );
	Wx::Event::EVT_MENU( $win,
		$menu_edit_select->Append( Wx::wxID_SELECTALL, Wx::gettext("Select all\tCtrl-A") ),
		sub { \&Padre::Wx::Editor::text_select_all(@_) },
	);
	$menu_edit_select->AppendSeparator;
	Wx::Event::EVT_MENU( $win,
		$menu_edit_select->Append( -1, Wx::gettext("Mark selection start\tCtrl-[") ),
		sub {
			my $editor = Padre->ide->wx->main_window->selected_editor or return;
			$editor->text_selection_mark_start;
		},
	);
	Wx::Event::EVT_MENU( $win,
		$menu_edit_select->Append( -1, Wx::gettext("Mark selection end\tCtrl-]") ),
		sub {
			my $editor = Padre->ide->wx->main_window->selected_editor or return;
			$editor->text_selection_mark_end;
		},
	);
	Wx::Event::EVT_MENU( $win,
		$menu_edit_select->Append( -1, Wx::gettext("Clear selection marks") ),
		\&Padre::Wx::Editor::text_selection_clear_marks,
	);


    
    Wx::Event::EVT_MENU( $win,
        $menu->Append( Wx::wxID_COPY, '' ),
		sub { Padre->ide->wx->main_window->selected_editor->Copy; }
    );
    Wx::Event::EVT_MENU( $win,
        $menu->Append( Wx::wxID_CUT, '' ),
		sub { Padre->ide->wx->main_window->selected_editor->Cut; }
    );
    Wx::Event::EVT_MENU( $win,
        $menu->Append( Wx::wxID_PASTE, '' ),
        sub { 
			my $editor = Padre->ide->wx->main_window->selected_editor or return;
			$editor->Paste;
		},
    );
    $menu->AppendSeparator;

	Wx::Event::EVT_MENU( $win,
		$menu->Append( Wx::wxID_FIND, '' ),
		sub { Padre::Wx::Dialog::Find->find(@_) },
	);
	Wx::Event::EVT_MENU( $win,
		$menu->Append( -1, Wx::gettext("Find Next\tF3") ),
		sub { Padre::Wx::Dialog::Find->find_next(@_) },
	);
	Wx::Event::EVT_MENU( $win,
		$menu->Append( -1, Wx::gettext("Find Previous\tShift-F3") ),
		sub { Padre::Wx::Dialog::Find->find_previous(@_) },
	);
	Wx::Event::EVT_MENU( $win,
		$menu->Append( -1, Wx::gettext("Ac&k") ),
		\&Padre::Wx::Ack::on_ack,
	);
	Wx::Event::EVT_MENU( $win,
		$menu->Append( -1, Wx::gettext("&Goto\tCtrl-G") ),
		\&Padre::Wx::MainWindow::on_goto,
	);
	Wx::Event::EVT_MENU( $win,
		$menu->Append( -1, Wx::gettext("&AutoComp\tCtrl-P") ),
		\&Padre::Wx::MainWindow::on_autocompletition,
	);
	Wx::Event::EVT_MENU( $win,
		$menu->Append( -1, Wx::gettext("&Brace matching\tCtrl-1") ),
		\&Padre::Wx::MainWindow::on_brace_matching,
	);
	Wx::Event::EVT_MENU( $win,
		$menu->Append( -1, Wx::gettext("&Join lines\tCtrl-J") ),
		\&Padre::Wx::MainWindow::on_join_lines,
	);
	Wx::Event::EVT_MENU( $win,
        $menu->Append( -1, Wx::gettext("Snippets\tCtrl-Shift-A") ),
        sub { Padre::Wx::Dialog::Snippets->snippets(@_) },
	); 
	$menu->AppendSeparator;

	# Commenting
	Wx::Event::EVT_MENU( $win,
		$menu->Append( -1, Wx::gettext("&Comment Selected Lines\tCtrl-M") ),
		\&Padre::Wx::MainWindow::on_comment_out_block,
	);
	Wx::Event::EVT_MENU( $win,
		$menu->Append( -1, Wx::gettext("&Uncomment Selected Lines\tCtrl-Shift-M") ),
		\&Padre::Wx::MainWindow::on_uncomment_block,
	);
	$menu->AppendSeparator;

	# Tab And Space
	my $menu_edit_tab = Wx::Menu->new;
	$menu->Append( -1, Wx::gettext("Tabs and Spaces"), $menu_edit_tab );
	Wx::Event::EVT_MENU( $win,
		$menu_edit_tab->Append( -1, Wx::gettext("Tabs to Spaces...") ),
		sub { $_[0]->on_tab_and_space('Tab_to_Space') },
	);
	Wx::Event::EVT_MENU( $win,
		$menu_edit_tab->Append( -1, Wx::gettext("Spaces to Tabs...") ),
		sub { $_[0]->on_tab_and_space('Space_to_Tab') },
	);
	Wx::Event::EVT_MENU( $win,
		$menu_edit_tab->Append( -1, Wx::gettext("Delete Trailing Spaces") ),
		sub { $_[0]->on_delete_ending_space() },
	);
	Wx::Event::EVT_MENU( $win,
		$menu_edit_tab->Append( -1, Wx::gettext("Delete Leading Spaces") ),
		sub { $_[0]->on_delete_leading_space() },
	);

	# Upper and Lower Case
	my $menu_edit_case = Wx::Menu->new;
	$menu->Append( -1, Wx::gettext("Upper/Lower Case"), $menu_edit_case );
	Wx::Event::EVT_MENU( $win,
		$menu_edit_case->Append( -1, Wx::gettext("Upper All\tCtrl-Shift-U") ),
		sub { Padre::Documents->current->editor->UpperCase; },
	);
	Wx::Event::EVT_MENU( $win,
		$menu_edit_case->Append( -1, Wx::gettext("Lower All\tCtrl-U") ),
		sub { Padre::Documents->current->editor->LowerCase; },
	);
	$menu->AppendSeparator;

	# Diff
	Wx::Event::EVT_MENU( $win,
		$menu->Append( -1, Wx::gettext("Diff") ),
		\&Padre::Wx::MainWindow::on_diff,
	);
	Wx::Event::EVT_MENU( $win,
		$menu->Append( -1, Wx::gettext("Insert From File...") ),
		\&Padre::Wx::MainWindow::on_insert_from_file,
	);
	$menu->AppendSeparator;

	# User Preferences
	Wx::Event::EVT_MENU( $win,
		$menu->Append( -1, Wx::gettext("&Preferences") ),
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
	$menu->{view_output} = $menu_view->AppendCheckItem( -1, Wx::gettext("Show Output") );
	Wx::Event::EVT_MENU( $win,
		$menu->{view_output},
		sub {
			$_[0]->show_output(
				$_[0]->{menu}->{view_output}->IsChecked
			),
		},
	);
	$menu->{view_functions} = $menu_view->AppendCheckItem( -1, Wx::gettext("Show Functions") );
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
		$menu->{view_statusbar} = $menu_view->AppendCheckItem( -1, Wx::gettext("Show StatusBar") );
		Wx::Event::EVT_MENU( $win,
			$menu->{view_statusbar},
			\&Padre::Wx::MainWindow::on_toggle_status_bar,
		);
	}
	$menu_view->AppendSeparator;

	# Editor look and feel
	$menu->{view_lines} = $menu_view->AppendCheckItem( -1, Wx::gettext("Show Line numbers") );
	Wx::Event::EVT_MENU( $win,
		$menu->{view_lines},
		\&Padre::Wx::MainWindow::on_toggle_line_numbers,
	);
	$menu->{view_folding} = $menu_view->AppendCheckItem( -1, Wx::gettext("Show Code Folding") );
	Wx::Event::EVT_MENU( $win,
		$menu->{view_folding},
		\&Padre::Wx::MainWindow::on_toggle_code_folding,
	);
	$menu->{view_eol} = $menu_view->AppendCheckItem( -1, Wx::gettext("Show Newlines") );
	Wx::Event::EVT_MENU( $win,
		$menu->{view_eol},
		\&Padre::Wx::MainWindow::on_toggle_eol,
	);
	$menu->{view_whitespaces} = $menu_view->AppendCheckItem( -1, Wx::gettext("Show Whitespaces") );
	Wx::Event::EVT_MENU( $win,
		$menu->{view_whitespaces},
		\&Padre::Wx::MainWindow::on_toggle_whitespaces,
	);

	$menu->{view_indentation_guide} = $menu_view->AppendCheckItem( -1, Wx::gettext("Show Indentation Guide") );
	Wx::Event::EVT_MENU( $win,
		$menu->{view_indentation_guide},
		\&Padre::Wx::MainWindow::on_toggle_indentation_guide,
	);
	$menu->{view_show_calltips} = $menu_view->AppendCheckItem( -1, Wx::gettext("Show Call Tips") );
	Wx::Event::EVT_MENU( $win,
		$menu->{view_show_calltips},
		sub { $config->{editor_calltips} = $menu->{view_show_calltips}->IsChecked },
	);
	$menu_view->AppendSeparator;
	
	$menu->{view_word_wrap} = $menu_view->AppendCheckItem( -1, Wx::gettext("Word-Wrap") );
	Wx::Event::EVT_MENU( $win,
		$menu->{view_word_wrap},
		sub {
			$_[0]->on_word_wrap(
				$_[0]->{menu}->{view_word_wrap}->IsChecked
			),
		},
	);
	$menu->{view_currentlinebackground} = $menu_view->AppendCheckItem( -1, Wx::gettext("Highlight Current Line") );
	Wx::Event::EVT_MENU( $win,
		$menu->{view_currentlinebackground},
		\&Padre::Wx::MainWindow::on_toggle_current_line_background,
	);
	$menu_view->AppendSeparator;

	Wx::Event::EVT_MENU( $win,
		$menu_view->Append( -1, Wx::gettext("Increase Font Size\tCtrl-+") ),
		sub { $_[0]->zoom(+1) },
	);
	Wx::Event::EVT_MENU( $win,
		$menu_view->Append( -1, Wx::gettext("Decrease Font Size\tCtrl--") ),
		sub { $_[0]->zoom(-1) },
	);
	Wx::Event::EVT_MENU( $win,
		$menu_view->Append( -1, Wx::gettext("Reset Font Size\tCtrl-/") ),
		sub { $_[0]->zoom( -1 * $_[0]->selected_editor->GetZoom ) },
	);

	$menu_view->AppendSeparator;
	Wx::Event::EVT_MENU( $win,
		$menu_view->Append( -1, Wx::gettext("Set Bookmark\tCtrl-B") ),
		sub { Padre::Wx::Dialog::Bookmarks->set_bookmark($_[0]) },
	);
	Wx::Event::EVT_MENU( $win,
		$menu_view->Append( -1, Wx::gettext("Goto Bookmark\tCtrl-Shift-B") ),
		sub { Padre::Wx::Dialog::Bookmarks->goto_bookmark($_[0]) },
	);

	$menu_view->AppendSeparator;
	$menu->{view_language} = Wx::Menu->new;
	$menu_view->Append( -1, Wx::gettext("Language"), $menu->{view_language} );
	
	# TODO horrible, fix this
	if ($config->{host}->{locale} eq 'en') {
		Wx::Event::EVT_MENU( $win,
			$menu->{view_language}->AppendRadioItem( -1, Wx::gettext("English") ),
			sub { $_[0]->change_locale('en') },
		);
		Wx::Event::EVT_MENU( $win,
			$menu->{view_language}->AppendRadioItem( -1, Wx::gettext("German") ),
			sub { $_[0]->change_locale('de') },
		);
	} else {
		Wx::Event::EVT_MENU( $win,
			$menu->{view_language}->AppendRadioItem( -1, Wx::gettext("German") ),
			sub { $_[0]->change_locale('de') },
		);
		Wx::Event::EVT_MENU( $win,
			$menu->{view_language}->AppendRadioItem( -1, Wx::gettext("English") ),
			sub { $_[0]->change_locale('en') },
		);
	}

	$menu_view->AppendSeparator;
	Wx::Event::EVT_MENU( $win,
		$menu_view->Append( -1, Wx::gettext("&Full screen\tF11") ),
		\&Padre::Wx::MainWindow::on_full_screen,
	);

	return $menu_view;
}

sub menu_perl {
	my ( $self, $win ) = @_;
	
	# Create the Perl menu
	my $menu = Wx::Menu->new;

	# Perl-Specific Searches
	my $menu_perl_find_unmatched = $menu->Append( -1, Wx::gettext("Find Unmatched Brace") );
	Wx::Event::EVT_MENU( $win,
		$menu_perl_find_unmatched,
		sub {
			my $doc = Padre::Documents->current;
			unless ( $doc and $doc->isa('Padre::Document::Perl') ) {
				return;
			}
			unless ($doc->find_unmatched_brace) {
				Wx::MessageBox( Wx::gettext("All braces appear to be matched"), Wx::gettext("Check Complete"), Wx::wxOK, $win );
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
	$menu->{run_run_script} = $menu_run->Append( -1, Wx::gettext("Run Script\tF5") );
	Wx::Event::EVT_MENU( $win,
		$menu->{run_run_script},
		sub { $_[0]->run_script },
	);
	$menu->{run_run_command} = $menu_run->Append( -1, Wx::gettext("Run Command\tCtrl-F5") );
	Wx::Event::EVT_MENU( $win,
		$menu->{run_run_command},
		sub { $_[0]->on_run_command },
	);
	$menu->{run_stop} = $menu_run->Append( -1, Wx::gettext("&Stop") );
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
	my $manager = Padre->ide->plugin_manager;
	my $plugins = $manager->plugins;
	my @plugins = grep { $_ ne 'My' } sort keys %$plugins;

	# Create the plugin menu
	my $menu = Wx::Menu->new;

	# Add the Plugin Tools menu
	my $tools = $self->menu_plugin_tools( $win );
	$menu->Append( -1, 'Plugin Tools', $tools );
	$menu->AppendSeparator;

	foreach my $name ( 'My', @plugins ) {
		next if not $plugins->{$name};
		#print "$name - $plugins{$name}{module} - $plugins{$name}{status}\n";
		next if not $plugins->{$name}{status} or $plugins->{$name}{status} ne 'loaded';

		#my $label = $manager->get_label($name);
		#my @menu  = $manager->get_menu($name);
		my ($label, $items) = $manager->get_menu($self->win, $name);
		
		#my $items = $self->add_plugin_menu_items(\@menu);
		$menu->Append( -1, $label, $items );
		if ( $name eq 'My' ) {
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
		$menu->Append( -1, Wx::gettext("Edit My Plugin") ),
		sub  {
			my $self = shift;
			my $file = File::Spec->catfile( Padre->ide->config_dir, 'plugins', 'Padre', 'Plugin', 'My.pm' );
			if (not -e $file) {
				return $self->error(Wx::gettext("Could not find the Padre::Plugin::My plugin"));
			}
			
			$self->setup_editor($file);
			$self->refresh_all;
		},
	);
	Wx::Event::EVT_MENU( $win,
		$menu->Append( -1, Wx::gettext("Reload My Plugin") ),
		sub { Padre->ide->plugin_manager->reload_plugin('My') },
	);
	Wx::Event::EVT_MENU( $win,
		$menu->Append( -1, Wx::gettext("Reset My Plugin") ),
		sub  {
			my $ret = Wx::MessageBox(
				Wx::gettext("Reset My Plugin"), Wx::gettext("Reset My Plugin"), Wx::wxOK | Wx::wxCANCEL | Wx::wxCENTRE, $win
			);
			if ( $ret == Wx::wxOK) {
				my $manager = Padre->ide->plugin_manager;
				my $target = File::Spec->catfile(
					$manager->plugin_dir, 'Padre', 'Plugin', 'My.pm'
				);
				$manager->unload_plugin("My");
				Padre::Config->copy_original_My_plugin($target);
				$manager->load_plugin("My");
			}
		},
	);
	$menu->AppendSeparator;

	Wx::Event::EVT_MENU( $win,
		$menu->Append( -1, Wx::gettext("Open Plugin Manager") ),
		sub { Padre::Wx::Dialog::PluginManager->show(@_) },
	);
	Wx::Event::EVT_MENU( $win,
		$menu->Append( -1, Wx::gettext("Reload All Plugins") ),
		sub { Padre->ide->plugin_manager->reload_plugins; },
	);
	Wx::Event::EVT_MENU( $win,
		$menu->Append( -1, Wx::gettext("Test A Plugin From Local Dir") ),
		sub { Padre->ide->plugin_manager->test_a_plugin; },
	);
	
	return $menu;
}

sub menu_window {
	my ( $self, $win ) = @_;
	
	# Create the window menu
	my $menu = Wx::Menu->new;
	Wx::Event::EVT_MENU( $win,
		$menu->Append( -1, Wx::gettext("&Split window") ),
		\&Padre::Wx::MainWindow::on_split_window,
	);
	$menu->AppendSeparator;
	Wx::Event::EVT_MENU( $win,
		$menu->Append(-1, Wx::gettext("Next File\tCtrl-TAB")),
		\&Padre::Wx::MainWindow::on_next_pane,
	);
	Wx::Event::EVT_MENU( $win,
		$menu->Append(-1, Wx::gettext("Previous File\tCtrl-Shift-TAB")),
		\&Padre::Wx::MainWindow::on_prev_pane,
	);
 	Wx::Event::EVT_MENU( $win,
 		$menu->Append(-1, Wx::gettext("Last Visited File\tCtrl-6")),
 		\&Padre::Wx::MainWindow::on_last_visited_pane,
	);
 	Wx::Event::EVT_MENU( $win,
 		$menu->Append(-1, Wx::gettext("Right Click\tCtrl-/")),
 		sub {
			my $editor = $_[0]->selected_editor;
			if ($editor) {
				$editor->on_right_down($_[1]);
			}
		},
	);
	$menu->AppendSeparator;


	Wx::Event::EVT_MENU( $win,
		$menu->Append( -1, Wx::gettext("GoTo Subs Window\tAlt-S") ),
		sub {
			$_[0]->{rightbar_was_closed} = ! Padre->ide->config->{main_rightbar};
			$_[0]->show_functions(1); 
			$_[0]->{rightbar}->SetFocus;
		},
	); 
	Wx::Event::EVT_MENU( $win,
		$menu->Append( -1, Wx::gettext("GoTo Output Window\tAlt-O") ),
		sub {
			$_[0]->show_output(1);
			$_[0]->{output}->SetFocus;
		},
	);
#	$self->{window_goto_synchk} = $menu->Append( -1, Wx::gettext("GoTo Syntax Check Window\tAlt-C") );
#	Wx::Event::EVT_MENU( $win,
#		$self->{window_goto_synchk},
#		sub {
#			$_[0]->show_syntaxbar(1);
#			$_[0]->{syntaxbar}->SetFocus;
#		},
#	);
#	unless ( $_[0]->{experimental_syntaxcheck}->IsChecked ) {
#		$self->{window_goto_synchk}->Enable(0);
#	}
	Wx::Event::EVT_MENU( $win,
		$menu->Append( -1, Wx::gettext("GoTo Main Window\tAlt-M") ),
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
		$menu->Append( -1, Wx::gettext("Context Help\tCtrl-Shift-H") ),
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
		$menu->Append( -1, Wx::gettext('Visit the PerlMonks') ),
		sub { Wx::LaunchDefaultBrowser('http://perlmonks.org/') },
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
		$menu_exp->Append( -1, Wx::gettext('Reflow Menu/Toolbar') ),
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
	$menu_exp->Append( -1, Wx::gettext("Recent Projects"), $menu->{file_recent_projects} );
	
	Wx::Event::EVT_MENU(
		$win,
		$menu_exp->Append( -1, Wx::gettext('Run in &Padre') ),
		sub {
			my $self = shift;
			my $code = Padre::Documents->current->text_get;
			eval $code;
			if ($@) {
				Wx::MessageBox(Wx::gettext("Error: ") . "$@", Wx::gettext("Self error"), Wx::wxOK, $self);
				return;
			}
			return;
		},
	);
	$menu->{experimental_syntaxcheck} = $menu_exp->AppendCheckItem( -1, Wx::gettext("Show Syntax Check") );
	Wx::Event::EVT_MENU( $win,
		$menu->{experimental_syntaxcheck},
		\&Padre::Wx::MainWindow::on_toggle_synchk,
	);

	
	$menu->{experimental_ppi_highlight} = $menu_exp->AppendCheckItem( -1, Wx::gettext("Use PPI for Perl5 syntax highlighting") );
	Wx::Event::EVT_MENU( $win,
		$menu->{experimental_ppi_highlight},
		\&Padre::Wx::MainWindow::on_ppi_highlight,
	);
	$menu->{experimental_ppi_highlight}->Check( $config->{ppi_highlight} ? 1 : 0 );
	$Padre::Document::MIME_LEXER{'application/x-perl'} = 
		$config->{ppi_highlight} ? Wx::wxSTC_LEX_CONTAINER : Wx::wxSTC_LEX_PERL;

	# Quick Find: Press F3 to start search with selected text
	$menu->{experimental_quick_find} = $menu_exp->AppendCheckItem( -1, Wx::gettext("Quick Find") );
	Wx::Event::EVT_MENU( $win,
		$menu->{experimental_quick_find},
		sub {
			$_[0]->on_quick_find(
				$_[0]->{menu}->{experimental_quick_find}->IsChecked
			),
		},
	);
	$menu->{experimental_quick_find}->Check( $config->{is_quick_find} ? 1 : 0 );

	# Incremental find (#60)
	Wx::Event::EVT_MENU( $win,
		$menu_exp->Append( -1, Wx::gettext("Find Next\tF4") ),
        	sub { $_[0]->find->search('next') },
	);
	Wx::Event::EVT_MENU( $win,
		$menu_exp->Append( -1, Wx::gettext("Find Previous\tShift-F4") ),
		sub { $_[0]->find->search('previous') }
	);

	return $menu_exp;
}

1;

# Copyright 2008 Gabor Szabo.
# LICENSE
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl 5 itself.
