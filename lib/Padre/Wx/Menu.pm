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

	# Create the File menu
	$menu->{file} = Wx::Menu->new;

	# Creating new things
	Wx::Event::EVT_MENU( $win,
		$menu->{file}->Append( Wx::wxID_NEW, '' ),
		sub {
			$_[0]->setup_editor;
			return;
		},
	);
	$menu->{file_new} = Wx::Menu->new;
	$menu->{file}->Append( -1, gettext("New..."), $menu->{file_new} );
	Wx::Event::EVT_MENU( $win,
		$menu->{file_new}->Append( -1, gettext('Perl Distribution (Module::Starter)') ),
		sub { Padre::Wx::Dialog::ModuleStart->start(@_) },
	);

	# Opening and closing files
	Wx::Event::EVT_MENU( $win,
		$menu->{file}->Append( Wx::wxID_OPEN, '' ),
		sub { $_[0]->on_open },
	);
	Wx::Event::EVT_MENU( $win,
		$menu->{file}->Append( -1, gettext("Open Selection\tCtrl-Shift-O") ),
		sub { $_[0]->on_open_selection },
	);
	Wx::Event::EVT_MENU( $win,
		$menu->{file}->Append( Wx::wxID_CLOSE,  '' ),
		sub { $_[0]->on_close },
	);
	Wx::Event::EVT_MENU( $win,
		$menu->{file}->Append( -1, gettext('Close All') ),
		sub { $_[0]->on_close_all },
	);
	Wx::Event::EVT_MENU( $win,
		$menu->{file}->Append( -1, gettext('Close All but Current Document') ),
		sub { $_[0]->on_close_all_but_current },
	);
	Wx::Event::EVT_MENU( $win,
		$menu->{file}->Append( -1, gettext('Reload file') ),
		sub { $_[0]->on_reload_file },
	);
	$menu->{file}->AppendSeparator;

	# Saving
	Wx::Event::EVT_MENU( $win,
		$menu->{file}->Append( Wx::wxID_SAVE, '' ),
		sub { $_[0]->on_save },
	);
	Wx::Event::EVT_MENU( $win,
		$menu->{file}->Append( Wx::wxID_SAVEAS, '' ),
		sub { $_[0]->on_save_as },
	);
	Wx::Event::EVT_MENU( $win,
		$menu->{file}->Append( -1, gettext('Save All') ),
		sub { $_[0]->on_save_all },
	);
	$menu->{file}->AppendSeparator;

	# Conversions and Transforms
	$menu->{file_convert} = Wx::Menu->new;
	$menu->{file}->Append( -1, gettext("Convert..."), $menu->{file_convert} );
	Wx::Event::EVT_MENU( $win,
		$menu->{file_convert}->Append(-1, gettext("EOL to Windows")),
		sub { $_[0]->convert_to("WIN") },
	);
	Wx::Event::EVT_MENU( $win,
		$menu->{file_convert}->Append(-1, gettext("EOL to Unix")),
		sub { $_[0]->convert_to("UNIX") },
	);
	Wx::Event::EVT_MENU( $win,
		$menu->{file_convert}->Append(-1, gettext("EOL to Mac")),
		sub { $_[0]->convert_to("MAC") },
	);
	$menu->{file}->AppendSeparator;

	# Recent things
	$menu->{file_recentfiles} = Wx::Menu->new;
	$menu->{file}->Append( -1, gettext("Recent Files"), $menu->{file_recentfiles} );
	foreach my $f ( Padre::DB->get_recent_files ) {
		next unless -f $f;
		Wx::Event::EVT_MENU( $win,
			$menu->{file_recentfiles}->Append(-1, $f), 
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
	$menu->{file}->AppendSeparator;
	
	# Word Stats
	Wx::Event::EVT_MENU( $win,
		$menu->{file}->Append( -1, gettext('Doc Stats') ),
		sub { $_[0]->on_doc_stats },
	);
	$menu->{file}->AppendSeparator;

	# Exiting
	Wx::Event::EVT_MENU( $win,
		$menu->{file}->Append( Wx::wxID_EXIT, '' ),
		sub { $_[0]->Close },
	);





	# Create the Edit menu
	$menu->{edit} = Wx::Menu->new;

	# Undo/Redo
	Wx::Event::EVT_MENU( $win, # Ctrl-Z
		$menu->{edit}->Append( Wx::wxID_UNDO, '' ),
		sub {
			my $editor = Padre::Documents->current->editor;
			if ( $editor->CanUndo ) {
				$editor->Undo;
			}
			return;
		},
	);
	Wx::Event::EVT_MENU( $win, # Ctrl-Y
		$menu->{edit}->Append( Wx::wxID_REDO, '' ),
		sub {
			my $editor = Padre::Documents->current->editor;
			if ( $editor->CanRedo ) {
				$editor->Redo;
			}
			return;
		},
	);
	$menu->{edit}->AppendSeparator;

    Wx::Event::EVT_MENU( $win,
        $menu->{edit}->Append( Wx::wxID_SELECTALL, gettext("Select all\tCtrl-A") ),
        sub { \&Padre::Wx::Editor::text_select_all(@_) },
    );
    Wx::Event::EVT_MENU( $win,
        $menu->{edit}->Append( Wx::wxID_COPY, '' ),
        sub { \&Padre::Wx::Editor::text_copy_to_clipboard(@_) },
    );
    Wx::Event::EVT_MENU( $win,
        $menu->{edit}->Append( Wx::wxID_CUT, '' ),
        sub { \&Padre::Wx::Editor::text_cut_to_clipboard(@_) },
    );
    Wx::Event::EVT_MENU( $win,
        $menu->{edit}->Append( Wx::wxID_PASTE, '' ),
        sub { \&Padre::Wx::Editor::text_paste_from_clipboard(@_) },
    );
    $menu->{edit}->AppendSeparator;

	Wx::Event::EVT_MENU( $win,
		$menu->{edit}->Append( Wx::wxID_FIND, '' ),
		sub { Padre::Wx::Dialog::Find->find(@_) },
	);
	Wx::Event::EVT_MENU( $win,
		$menu->{edit}->Append( -1, gettext("&Find Next\tF3") ),
		sub { Padre::Wx::Dialog::Find->find_next(@_) },
	);
	Wx::Event::EVT_MENU( $win,
		$menu->{edit}->Append( -1, gettext("Find Previous\tShift-F3") ),
		sub { Padre::Wx::Dialog::Find->find_previous(@_) },
	);
	Wx::Event::EVT_MENU( $win,
		$menu->{edit}->Append( -1, gettext("Ac&k") ),
		\&Padre::Wx::Ack::on_ack,
	);
	Wx::Event::EVT_MENU( $win,
		$menu->{edit}->Append( -1, gettext("&Goto\tCtrl-G") ),
		\&Padre::Wx::MainWindow::on_goto,
	);
	Wx::Event::EVT_MENU( $win,
		$menu->{edit}->Append( -1, gettext("&AutoComp\tCtrl-P") ),
		\&Padre::Wx::MainWindow::on_autocompletition,
	);
	Wx::Event::EVT_MENU( $win,
		$menu->{edit}->Append( -1, gettext("Subs\tAlt-S") ),
		sub { $_[0]->{rightbar}->SetFocus },
	); 
	Wx::Event::EVT_MENU( $win,
		$menu->{edit}->Append( -1, gettext("&Brace matching\tCtrl-1") ),
		\&Padre::Wx::MainWindow::on_brace_matching,
	);
	$menu->{edit}->AppendSeparator;

	# Commenting
	Wx::Event::EVT_MENU( $win,
		$menu->{edit}->Append( -1, gettext("&Comment Selected Lines\tCtrl-M") ),
		\&Padre::Wx::MainWindow::on_comment_out_block,
	);
	Wx::Event::EVT_MENU( $win,
		$menu->{edit}->Append( -1, gettext("&Uncomment Selected Lines\tCtrl-Shift-M") ),
		\&Padre::Wx::MainWindow::on_uncomment_block,
	);
	$menu->{edit}->AppendSeparator;

	# Tab And Space
	$menu->{edit_tab} = Wx::Menu->new;
	$menu->{edit}->Append( -1, gettext("Tab and Space"), $menu->{edit_tab} );
	Wx::Event::EVT_MENU( $win,
		$menu->{edit_tab}->Append( -1, gettext("Tab to Space...") ),
		sub { $_[0]->on_tab_and_space('Tab_to_Space') },
	);
	Wx::Event::EVT_MENU( $win,
		$menu->{edit_tab}->Append( -1, gettext("Space to Tab...") ),
		sub { $_[0]->on_tab_and_space('Space_to_Tab') },
	);
	Wx::Event::EVT_MENU( $win,
		$menu->{edit_tab}->Append( -1, gettext("Delete All Ending Space") ),
		sub { $_[0]->on_delete_ending_space() },
	);
	Wx::Event::EVT_MENU( $win,
		$menu->{edit_tab}->Append( -1, gettext("Delete Leading Space...") ),
		sub { $_[0]->on_delete_leading_space() },
	);

	# Upper and Lower Case
	$menu->{edit_case} = Wx::Menu->new;
	$menu->{edit}->Append( -1, gettext("Upper/Lower Case"), $menu->{edit_case} );
	Wx::Event::EVT_MENU( $win,
		$menu->{edit_case}->Append( -1, gettext("Upper All") ),
		sub { $_[0]->on_upper_and_lower('Upper_All') },
	);
	Wx::Event::EVT_MENU( $win,
		$menu->{edit_case}->Append( -1, gettext("Lower All") ),
		sub { $_[0]->on_upper_and_lower('Lower_All') },
	);
	Wx::Event::EVT_MENU( $win,
		$menu->{edit_case}->Append( -1, gettext("Upper First") ),
		sub { $_[0]->on_upper_and_lower('Upper_First') },
	);
	Wx::Event::EVT_MENU( $win,
		$menu->{edit_case}->Append( -1, gettext("Lower First") ),
		sub { $_[0]->on_upper_and_lower('Lower_First') },
	);
	$menu->{edit}->AppendSeparator;

	# Diff
	Wx::Event::EVT_MENU( $win,
		$menu->{edit}->Append( -1, gettext("Diff") ),
		\&Padre::Wx::MainWindow::on_diff,
	);
	$menu->{edit}->AppendSeparator;

	# User Preferences
	Wx::Event::EVT_MENU( $win,
		$menu->{edit}->Append( -1, gettext("&Preferences") ),
		\&Padre::Wx::MainWindow::on_preferences,
	);





	# Create the View menu
	$menu->{view}       = Wx::Menu->new;
	$menu->{view_lines} = $menu->{view}->AppendCheckItem( -1, gettext("Show Line numbers") );
	Wx::Event::EVT_MENU( $win,
		$menu->{view_lines},
		\&Padre::Wx::MainWindow::on_toggle_line_numbers,
	);
	$menu->{view_eol} = $menu->{view}->AppendCheckItem( -1, gettext("Show Newlines") );
	Wx::Event::EVT_MENU( $win,
		$menu->{view_eol},
		\&Padre::Wx::MainWindow::on_toggle_eol,
	);
	$menu->{view_output} = $menu->{view}->AppendCheckItem( -1, gettext("Show Output") );
	Wx::Event::EVT_MENU( $win,
		$menu->{view_output},
		sub {
			$_[0]->show_output(
				$_[0]->{menu}->{view_output}->IsChecked
			),
		},
	);
	unless ( Padre::Util::WIN32 ) {
		# On Windows disabling the status bar is broken, so don't allow it
		$menu->{view_statusbar} = $menu->{view}->AppendCheckItem( -1, gettext("Show StatusBar") );
		Wx::Event::EVT_MENU( $win,
			$menu->{view_statusbar},
			\&Padre::Wx::MainWindow::on_toggle_status_bar,
		);
	}
	$menu->{view_indentation_guide} = $menu->{view}->AppendCheckItem( -1, gettext("Show Indentation Guide") );
	Wx::Event::EVT_MENU( $win,
		$menu->{view_indentation_guide},
		\&Padre::Wx::MainWindow::on_toggle_indentation_guide,
	);
	$menu->{view_show_calltips} = $menu->{view}->AppendCheckItem( -1, gettext("Show Call Tips") );
	Wx::Event::EVT_MENU( $win,
		$menu->{view_show_calltips},
		sub { $config->{editor_calltips} = $menu->{view_show_calltips}->IsChecked },
	);
	$menu->{view}->AppendSeparator;

	Wx::Event::EVT_MENU( $win,
		$menu->{view}->Append( -1, gettext("Increase Font Size\tCtrl-+") ),
		sub { $_[0]->zoom(+1) },
	);
	Wx::Event::EVT_MENU( $win,
		$menu->{view}->Append( -1, gettext("Decrease Font Size\tCtrl--") ),
		sub { $_[0]->zoom(-1) },
	);
	Wx::Event::EVT_MENU( $win,
		$menu->{view}->Append( -1, gettext("Reset Font Size\tCtrl-/") ),
		sub { $_[0]->zoom( -1 * $_[0]->selected_editor->GetZoom ) },
	);

	$menu->{view}->AppendSeparator;
	Wx::Event::EVT_MENU( $win,
		$menu->{view}->Append( -1, gettext("Set Bookmark\tCtrl-B") ),
		sub { Padre::Wx::Dialog::Bookmarks->set_bookmark($_[0]) },
	);
	Wx::Event::EVT_MENU( $win,
		$menu->{view}->Append( -1, gettext("Goto Bookmark\tCtrl-Shift-B") ),
		sub { Padre::Wx::Dialog::Bookmarks->goto_bookmark($_[0]) },
	);

	$menu->{view}->AppendSeparator;
	$menu->{view_language} = Wx::Menu->new;
	$menu->{view}->Append( -1, gettext("Language"), $menu->{view_language} );
	
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

	# Create the Perl menu
	$menu->{perl} = Wx::Menu->new;

	# Perl-Specific Searches
	$menu->{perl_find_unmatched} = $menu->{perl}->Append( -1, gettext("Find Unmatched Brace") );
	Wx::Event::EVT_MENU( $win,
		$menu->{perl_find_unmatched},
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


	# Create the Run menu
	$menu->{run} = Wx::Menu->new;

	# Script Execution
	$menu->{run_run_script} = $menu->{run}->Append( -1, gettext("Run Script\tF5") );
	Wx::Event::EVT_MENU( $win,
		$menu->{run_run_script},
		sub { $_[0]->run_script },
	);
	$menu->{run_run_command} = $menu->{run}->Append( -1, gettext("Run Command\tCtrl-F5") );
	Wx::Event::EVT_MENU( $win,
		$menu->{run_run_command},
		sub { $_[0]->on_run_command },
	);
	$menu->{run_stop} = $menu->{run}->Append( -1, gettext("&Stop") );
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




	# Create the Plugins menu if there are any plugins
	my %plugins = %{ $ide->plugin_manager->plugins };
	if ( %plugins ) {
		$menu->{plugin} = Wx::Menu->new;
	}
	foreach my $name ( sort keys %plugins ) {
		next if not $plugins{$name};
		my @menu       = eval { $plugins{$name}->menu };
		warn "Error when calling menu for plugin '$name' $@" if $@;
		my $menu_items = $menu->add_plugin_menu_items(\@menu);
		my $menu_name  = eval { $plugins{$name}->menu_name };
		if (not $menu_name) {
			$menu_name = $name;
			$menu_name =~ s/::/ /;
		}
		$menu->{plugin}->Append( -1, $menu_name, $menu_items );
	}





	# Create the window menu
	$menu->{window} = Wx::Menu->new;
	Wx::Event::EVT_MENU( $win,
		$menu->{window}->Append( -1, gettext("&Split window") ),
		\&Padre::Wx::MainWindow::on_split_window,
	);
	$menu->{window}->AppendSeparator;
	Wx::Event::EVT_MENU( $win,
		$menu->{window}->Append(-1, gettext("Next File\tCtrl-TAB")),
		\&Padre::Wx::MainWindow::on_next_pane,
	);
	Wx::Event::EVT_MENU( $win,
		$menu->{window}->Append(-1, gettext("Previous File\tCtrl-Shift-TAB")),
		\&Padre::Wx::MainWindow::on_prev_pane,
	);
	$menu->{window}->AppendSeparator;





	# Create the help menu
	$menu->{help} = Wx::Menu->new;
	my $help = Padre::Wx::Menu::Help->new;

	Wx::Event::EVT_MENU( $win,
		$menu->{help}->Append( Wx::wxID_HELP, '' ),
		sub { $help->help($win) },
	);
	Wx::Event::EVT_MENU( $win,
		$menu->{help}->Append( -1, gettext("Context Help\tCtrl-Shift-H") ),
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
	$menu->{help}->AppendSeparator;
	Wx::Event::EVT_MENU( $win,
		$menu->{help}->Append( Wx::wxID_ABOUT, '' ),
		sub { $help->about },
	);





	# Create the Experimental menu
	# All the crap that doesn't work, have a home,
	# or should never be seen be real users goes here.
	if ( $experimental ) {
		$menu->{experimental} = Wx::Menu->new;
		Wx::Event::EVT_MENU( $win,
			$menu->{experimental}->Append( -1, gettext('Reflow Menu/Toolbar') ),
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
		$menu->{experimental}->Append( -1, gettext("Recent Projects"), $menu->{file_recent_projects} );
		
		Wx::Event::EVT_MENU(
			$win,
			$menu->{experimental}->Append( -1, gettext('Run in &Padre') ),
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
		$menu->{experimental_ppi_highlight} = $menu->{experimental}->AppendCheckItem( -1, gettext("Use PPI for Perl5 syntax highlighting") );
		Wx::Event::EVT_MENU( $win,
			$menu->{experimental_ppi_highlight},
			\&Padre::Wx::MainWindow::on_ppi_highlight,
		);
		$menu->{experimental_ppi_highlight}->Check( $config->{ppi_highlight} ? 1 : 0 );
		$Padre::Document::MIME_LEXER{'application/x-perl'} = 
			$config->{ppi_highlight} ? Wx::wxSTC_LEX_CONTAINER : Wx::wxSTC_LEX_PERL;

	}

	# Create and return the main menu bar
	$menu->{wx} = Wx::MenuBar->new;
	$menu->{wx}->Append( $menu->{file},     gettext("&File")      );
	$menu->{wx}->Append( $menu->{project},  gettext("&Project")   );
	$menu->{wx}->Append( $menu->{edit},     gettext("&Edit")      );
	$menu->{wx}->Append( $menu->{view},     gettext("&View")      );
	#$menu->{wx}->Append( $menu->{perl},     gettext("Perl")       );
	$menu->{wx}->Append( $menu->{run},      gettext("Run")        );
	$menu->{wx}->Append( $menu->{bookmark}, gettext("&Bookmarks") );
	$menu->{wx}->Append( $menu->{plugin},   gettext("Pl&ugins")   ) if $menu->{plugin};
	$menu->{wx}->Append( $menu->{window},   gettext("&Window")    );
	$menu->{wx}->Append( $menu->{help},     gettext("&Help")      );
	if ( $experimental ) {
		$menu->{wx}->Append( $menu->{experimental}, gettext("E&xperimental") );
	}

	# Setup menu state from configuration
	$menu->{view_lines}->Check( $config->{editor_linenumbers} ? 1 : 0 );
	$menu->{view_eol}->Check( $config->{editor_eol} ? 1 : 0 );
	unless ( Padre::Util::WIN32 ) {
		$menu->{view_statusbar}->Check( $config->{main_statusbar} ? 1 : 0 );
	}
	$menu->{view_output}->Check( $config->{main_output} ? 1 : 0 );

	$menu->{view_indentation_guide}->Check( $config->{editor_indentationguides} ? 1 : 0 );
	$menu->{view_show_calltips}->Check( $config->{editor_calltips} ? 1 : 0 );

	return $menu;
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
	return if $n > 9;

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

	$self->{alt}->[$n]->SetText("$file\tAlt-$v");

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

	if ( _INSTANCE($document, 'Padre::Document::Perl') and $self->{wx}->GetMenuLabel(3) ne 'Perl') {
		$self->{wx}->Insert( 3, $self->{perl}, "Perl" );
	} elsif ( not _INSTANCE($document, 'Padre::Document::Perl') and $self->{wx}->GetMenuLabel(3) eq 'Perl') {
		$self->{wx}->Remove( 3 );
	}

	return 1;

	# Create the new menu bar
	$self->{wx} = Wx::MenuBar->new;
	$self->{wx}->Append( $self->{file},     gettext("&File")      );
	$self->{wx}->Append( $self->{project},  gettext("&Project")   );
	$self->{wx}->Append( $self->{edit},     gettext("&Edit")      );
	$self->{wx}->Append( $self->{view},     gettext("&View")      );
	if ( _INSTANCE($document, 'Padre::Document::Perl') ) {
		$self->{wx}->Append( $self->{perl}, gettext("Perl") );
	}
	$self->{wx}->Append( $self->{bookmark}, gettext("&Bookmarks") );
	$self->{wx}->Append( $self->{plugin},   gettext("Pl&ugins")   ) if $self->{plugin};
	$self->{wx}->Append( $self->{window},   gettext("&Window")    );
	$self->{wx}->Append( $self->{help},     gettext("&Help")      );
	if ( Padre->ide->config->{experimental} ) {
		$self->{wx}->Append( $self->{experimental}, gettext("E&xperimental") );
	}
	$self->win->SetMenuBar( $self->{wx} );

	return 1;
}

1;

# Copyright 2008 Gabor Szabo.
# LICENSE
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl 5 itself.
