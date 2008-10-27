package Padre::Wx::Menu;

use 5.008;
use strict;
use warnings;
use Params::Util qw{_INSTANCE};

use Padre::Wx        ();
use Padre::Util      ();
use Padre::Documents ();

our $VERSION = '0.14';





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

	# Opening and closing files
	Wx::Event::EVT_MENU( $win,
		$menu->{file}->Append( Wx::wxID_NEW, '' ),
		sub {
			$_[0]->setup_editor;
			return;
		},
	);
	Wx::Event::EVT_MENU( $win,
		$menu->{file}->Append( Wx::wxID_OPEN, '' ),
		sub { $_[0]->on_open },
	);
	Wx::Event::EVT_MENU( $win,
		$menu->{file}->Append( -1, "Open Selection\tCtrl-Shift-O" ),
		sub { $_[0]->on_open_selection },
	);
	Wx::Event::EVT_MENU( $win,
		$menu->{file}->Append( Wx::wxID_CLOSE,  '' ),
		sub { $_[0]->on_close },
	);
	Wx::Event::EVT_MENU( $win,
		$menu->{file}->Append( -1, 'Close All' ),
		sub { $_[0]->on_close_all },
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
		$menu->{file}->Append( -1, 'Save All' ),
		sub { $_[0]->on_save_all },
	);
	$menu->{file}->AppendSeparator;

	# Conversions and Transforms
	$menu->{file_convert} = Wx::Menu->new;
	$menu->{file}->Append( -1, "Convert...", $menu->{file_convert} );
	Wx::Event::EVT_MENU( $win,
		$menu->{file_convert}->Append(-1, "EOL to Windows"),
		sub { $_[0]->convert_to("WIN") },
	);
	Wx::Event::EVT_MENU( $win,
		$menu->{file_convert}->Append(-1, "EOL to Unix"),
		sub { $_[0]->convert_to("UNIX") },
	);
	Wx::Event::EVT_MENU( $win,
		$menu->{file_convert}->Append(-1, "EOL to Mac"),
		sub { $_[0]->convert_to("MAC") },
	);
	$menu->{file}->AppendSeparator;

	# Recent things
	$menu->{file_recentfiles} = Wx::Menu->new;
	$menu->{file}->Append( -1, "Recent Files", $menu->{file_recentfiles} );
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
	if ( $experimental ) {
		$menu->{file_recent_projects} = Wx::Menu->new;
		$menu->{file}->Append( -1, "Recent Projects", $menu->{file_recent_projects} );
	}
	$menu->{file}->AppendSeparator;

	# Module::Start
	Wx::Event::EVT_MENU( $win,
		$menu->{file}->Append( -1, 'Start Module' ),
		\&Padre::Wx::ModuleStartDialog::on_start,
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
			my $page = Padre::Documents->current->editor;
			if ( $page->CanUndo ) {
				$page->Undo;
			}
			return;
		},
	);
	Wx::Event::EVT_MENU( $win, # Ctrl-Y
		$menu->{edit}->Append( Wx::wxID_REDO, '' ),
		sub {
			my $page = Padre::Documents->current->editor;
			if ( $page->CanRedo ) {
				$page->Redo;
			}
			return;
		},
	);
	$menu->{edit}->AppendSeparator;

	# Random shit that doesn't fit anywhere better yet
	Wx::Event::EVT_MENU( $win,
		$menu->{edit}->Append( Wx::wxID_FIND, '' ),
		\&Padre::Wx::FindDialog::on_find,
	);
	Wx::Event::EVT_MENU( $win,
		$menu->{edit}->Append( -1, "&Find Next\tF3" ),
		\&Padre::Wx::FindDialog::on_find_next,
	);
	Wx::Event::EVT_MENU( $win,
		$menu->{edit}->Append( -1, "Find Previous\tShift-F3" ),
		\&Padre::Wx::FindDialog::on_find_previous,
	);
	Wx::Event::EVT_MENU( $win,
		$menu->{edit}->Append( -1, "Ac&k" ),
		\&Padre::Wx::Ack::on_ack,
	);
	Wx::Event::EVT_MENU( $win,
		$menu->{edit}->Append( -1, "&Goto\tCtrl-G" ),
		\&Padre::Wx::GoToLine::on_goto,
	);
	Wx::Event::EVT_MENU( $win,
		$menu->{edit}->Append( -1, "&AutoComp\tCtrl-P" ),
		\&Padre::Wx::MainWindow::on_autocompletition,
	);
	Wx::Event::EVT_MENU( $win,
		$menu->{edit}->Append( -1, "Subs\tAlt-S" ),
		sub { $_[0]->{rightbar}->SetFocus },
	); 
	Wx::Event::EVT_MENU( $win,
		$menu->{edit}->Append( -1, "&Brace matching\tCtrl-1" ),
		\&Padre::Wx::MainWindow::on_brace_matching,
	);
	$menu->{edit}->AppendSeparator;

	# User Preferences
	Wx::Event::EVT_MENU( $win,
		$menu->{edit}->Append( -1, "&Preferences" ),
		\&Padre::Wx::MainWindow::on_preferences,
	);





	# Create the View menu
	$menu->{view}       = Wx::Menu->new;
	$menu->{view_lines} = $menu->{view}->AppendCheckItem( -1, "Show Line numbers" );
	Wx::Event::EVT_MENU( $win,
		$menu->{view_lines},
		\&Padre::Wx::MainWindow::on_toggle_line_numbers,
	);
	$menu->{view_eol} = $menu->{view}->AppendCheckItem( -1, "Show Newlines" );
	Wx::Event::EVT_MENU( $win,
		$menu->{view_eol},
		\&Padre::Wx::MainWindow::on_toggle_eol,
	);
	$menu->{view_output} = $menu->{view}->AppendCheckItem( -1, "Show Output" );
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
		$menu->{view_statusbar} = $menu->{view}->AppendCheckItem( -1, "Show StatusBar" );
		Wx::Event::EVT_MENU( $win,
			$menu->{view_statusbar},
			\&Padre::Wx::MainWindow::on_toggle_status_bar,
		);
	}
	$menu->{view_indentation_guide} = $menu->{view}->AppendCheckItem( -1, "Show Indentation Guide" );
	Wx::Event::EVT_MENU( $win,
		$menu->{view_indentation_guide},
		\&Padre::Wx::MainWindow::on_toggle_indentation_guide,
	);
	$menu->{view_show_calltips} = $menu->{view}->AppendCheckItem( -1, "Show Call Tips" );
	Wx::Event::EVT_MENU( $win,
		$menu->{view_show_calltips},
		sub { $config->{editor_calltips} = $menu->{view_show_calltips}->IsChecked },
	);
	$menu->{view}->AppendSeparator;

	Wx::Event::EVT_MENU( $win,
		$menu->{view}->Append( -1, "Increase Font Size\tCtrl--" ),
		sub { $_[0]->zoom(+1) },
	);
	Wx::Event::EVT_MENU( $win,
		$menu->{view}->Append( -1, "Decrease Font Size\tCtrl-+" ),
		sub { $_[0]->zoom(-1) },
	);
	Wx::Event::EVT_MENU( $win,
		$menu->{view}->Append( -1, "Reset Font Size\tCtrl-/" ),
		sub { $_[0]->zoom( -1 * $_[0]->selected_editor->GetZoom ) },
	);

	$menu->{view}->AppendSeparator;
	Wx::Event::EVT_MENU( $win,
		$menu->{view}->Append( -1, "Set Bookmark\tCtrl-B" ),
		sub { Padre::Wx::Bookmarks::on_set_bookmark($_[0]) },
	);
	Wx::Event::EVT_MENU( $win,
		$menu->{view}->Append( -1, "Goto Bookmark\tCtrl-Shift-B" ),
		sub { Padre::Wx::Bookmarks::on_goto_bookmark($_[0]) },
	);




	# Create the Perl menu
	$menu->{perl} = Wx::Menu->new;

	# Perl-Specific Searches
	$menu->{perl_find_unmatched} = $menu->{perl}->Append( -1, "Find Unmatched Brace" );
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
				Wx::MessageBox( "All braces appear to be matched", "Check Complete", Wx::wxOK, $win );
			}
		},
	);
	$menu->{perl}->AppendSeparator;

	# Script Execution
	$menu->{perl_run_script} = $menu->{perl}->Append( -1, "Run Script\tF5" );
	Wx::Event::EVT_MENU( $win,
		$menu->{perl_run_script},
		sub { $_[0]->run_perl },
	);
	$menu->{perl_run_command} = $menu->{perl}->Append( -1, "Run Command\tCtrl-F5" );
	Wx::Event::EVT_MENU( $win,
		$menu->{perl_run_command},
		sub {
			$DB::single = 1;
			my $main_window = shift;
			require Padre::Wx::History::TextDialog;
			my $dialog = Padre::Wx::History::TextDialog->new(
				$main_window,
				"Command line",
				"Run setup",
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
	);
	$menu->{perl_stop} = $menu->{perl}->Append( -1, "&Stop" );
	Wx::Event::EVT_MENU( $win,
		$menu->{perl_stop},
		sub {
			if ( $_[0]->{command} ) {
				$_[0]->{command}->TerminateProcess;
			}
			delete $_[0]->{command};
			return;
		},
	);
	$menu->{perl_stop}->Enable(0);

	# Commenting
	Wx::Event::EVT_MENU( $win,
		$menu->{perl}->Append( -1, "&Comment Selected Lines\tCtrl-M" ),
		\&Padre::Wx::MainWindow::on_comment_out_block,
	);
	Wx::Event::EVT_MENU( $win,
		$menu->{perl}->Append( -1, "&Uncomment Selected Lines\tCtrl-Shift-M" ),
		\&Padre::Wx::MainWindow::on_uncomment_block,
	);





	# Create the Plugins menu if there are any plugins
	my %plugins = %{ $ide->plugin_manager->plugins };
	if ( %plugins ) {
		$menu->{plugin} = Wx::Menu->new;
	}
	foreach my $name ( sort keys %plugins ) {
		next if not $plugins{$name};
		my @menu    = eval { $plugins{$name}->menu };
		warn "Error when calling menu for plugin '$name' $@" if $@;
		my $menu_items = $menu->add_plugin_menu_items(\@menu);
		$menu->{plugin}->Append( -1, $name, $menu_items );
	}





	# Create the window menu
	$menu->{window} = Wx::Menu->new;
	if ( $experimental ) {
		Wx::Event::EVT_MENU( $win,
			$menu->{window}->Append( -1, "&Split window" ),
			\&Padre::Wx::MainWindow::on_split_window,
		);
		$menu->{window}->AppendSeparator;
	}
	Wx::Event::EVT_MENU( $win,
		$menu->{window}->Append(-1, "Next File\tCtrl-TAB"),
		\&Padre::Wx::MainWindow::on_next_pane,
	);
	Wx::Event::EVT_MENU( $win,
		$menu->{window}->Append(-1, "Previous File\tCtrl-Shift-TAB"),
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
		$menu->{help}->Append( -1, "Context Help\tCtrl-Shift-H" ),
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
			$menu->{experimental}->Append( -1, 'Reflow Menu/Toolbar' ),
			sub {
				$DB::single = 1;
				my $document = Padre::Documents->current;
				$_[0]->{menu}->refresh( $document );
				$_[0]->SetMenuBar( $_[0]->{menu}->{wx} );
				$_[0]->GetToolBar->refresh( $document );
				return;
			},
		);
		Wx::Event::EVT_MENU(
			$win,
			$menu->{experimental}->Append( -1, 'Run in &Padre' ),
			sub {
				my $self = shift;
				my $code = Padre::Documents->current->text_get;
				eval $code;
				if ($@) {
					Wx::MessageBox("Error: $@", "Self error", Wx::wxOK, $self);
					return;
				}
				return;
			},
		);
	}

	# Create and return the main menu bar
	$menu->{wx} = Wx::MenuBar->new;
	$menu->{wx}->Append( $menu->{file},     "&File"      );
	$menu->{wx}->Append( $menu->{project},  "&Project"   );
	$menu->{wx}->Append( $menu->{edit},     "&Edit"      );
	$menu->{wx}->Append( $menu->{view},     "&View"      );
	#$menu->{wx}->Append( $menu->{perl},     "Perl"       );
	$menu->{wx}->Append( $menu->{bookmark}, "&Bookmarks" );
	$menu->{wx}->Append( $menu->{plugin},   "Pl&ugins"   ) if $menu->{plugin};
	$menu->{wx}->Append( $menu->{window},   "&Window"    );
	$menu->{wx}->Append( $menu->{help},     "&Help"      );
	if ( $experimental ) {
		$menu->{wx}->Append( $menu->{experimental}, "E&xperimental" );
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
	$self->{wx}->Append( $self->{file},     "&File"      );
	$self->{wx}->Append( $self->{project},  "&Project"   );
	$self->{wx}->Append( $self->{edit},     "&Edit"      );
	$self->{wx}->Append( $self->{view},     "&View"      );
	if ( _INSTANCE($document, 'Padre::Document::Perl') ) {
		$self->{wx}->Append( $self->{perl}, "Perl" );
	}
	$self->{wx}->Append( $self->{bookmark}, "&Bookmarks" );
	$self->{wx}->Append( $self->{plugin},   "Pl&ugins"   ) if $self->{plugin};
	$self->{wx}->Append( $self->{window},   "&Window"    );
	$self->{wx}->Append( $self->{help},     "&Help"      );
	if ( Padre->ide->config->{experimental} ) {
		$self->{wx}->Append( $self->{experimental}, "E&xperimental" );
	}
	$self->win->SetMenuBar( $self->{wx} );

	return 1;
}

1;
