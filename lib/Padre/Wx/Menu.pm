package Padre::Wx::Menu;

use 5.008;
use strict;
use warnings;
use Padre::Util  ();
use Params::Util qw{_INSTANCE};
use Wx           qw(:everything);
use Wx::Event    qw(:everything);

our $VERSION = '0.10';





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
    EVT_MENU( $win,
        $menu->{file}->Append( wxID_NEW, '' ),
        sub {
            $_[0]->setup_editor;
            return;
        },
    );
    EVT_MENU( $win,
        $menu->{file}->Append( wxID_OPEN, '' ),
        sub { $_[0]->on_open },
    );
    EVT_MENU( $win,
        $menu->{file}->Append( -1, "Open Selection\tCtrl-Shift-O" ),
        sub { $_[0]->on_open_selection },
    );
    EVT_MENU( $win,
        $menu->{file}->Append( wxID_CLOSE,  '' ),
        sub { $_[0]->close },
    );
    EVT_MENU( $win,
        $menu->{file}->Append( -1, 'Close All' ),
        sub { $_[0]->on_close_all },
    );
    $menu->{file}->AppendSeparator;

	# Saving
	EVT_MENU( $win,
		$menu->{file}->Append( wxID_SAVE, '' ),
		sub { $_[0]->on_save },
	);
	EVT_MENU( $win,
		$menu->{file}->Append( wxID_SAVEAS, '' ),
		sub { $_[0]->on_save_as },
	);
	EVT_MENU( $win,
		$menu->{file}->Append( -1, 'Save All' ),
		sub { $_[0]->on_save_all },
	);
	$menu->{file}->AppendSeparator;

	# Conversions and Transforms
	$menu->{file_convert} = Wx::Menu->new;
	$menu->{file}->Append( -1, "Convert...", $menu->{file_convert} );
	EVT_MENU( $win,
		$menu->{file_convert}->Append(-1, "EOL to Windows"),
		sub { $_[0]->convert_to("WIN") },
	);
	EVT_MENU( $win,
		$menu->{file_convert}->Append(-1, "EOL to Unix"),
		sub { $_[0]->convert_to("UNIX") },
	);
	EVT_MENU( $win,
		$menu->{file_convert}->Append(-1, "EOL to Mac"),
		sub { $_[0]->convert_to("MAC") },
	);
	$menu->{file}->AppendSeparator;

    # Recent things
    $menu->{file_recentfiles} = Wx::Menu->new;
    $menu->{file}->Append( -1, "Recent Files", $menu->{file_recentfiles} );
    foreach my $f ( Padre::DB->get_recent_files ) {
       next unless -f $f;
       EVT_MENU( $win,
           $menu->{file_recentfiles}->Append(-1, $f), 
           sub { $_[0]->setup_editor($f) },
       );
    }
    if ( $experimental ) {
        $menu->{file_recent_projects} = Wx::Menu->new;
        $menu->{file}->Append( -1, "Recent Projects", $menu->{file_recent_projects} );
        # $menu->{file_recent_projects}->Enable(0);
    }
    $menu->{file}->AppendSeparator;

    # Exiting
    EVT_MENU( $win,
        $menu->{file}->Append( wxID_EXIT, '' ),
        sub { $_[0]->on_exit },
    );





    # Create the Edit menu
    $menu->{edit} = Wx::Menu->new;

    # Undo/Redo
    EVT_MENU( $win, # Ctrl-Z
        $menu->{edit}->Append( wxID_UNDO, '' ),
        sub {
            my $page = Padre::Document->from_selection->editor;
            if ( $page->CanUndo ) {
               $page->Undo;
            }
            return;
        },
    );
    EVT_MENU( $win, # Ctrl-Y
        $menu->{edit}->Append( wxID_REDO, '' ),
        sub {
            my $page = Padre::Document->from_selection->editor;
            if ( $page->CanRedo ) {
               $page->Redo;
            }
            return;
        },
    );
    $menu->{edit}->AppendSeparator;

    # Random shit that doesn't fit anywhere better yet
    EVT_MENU( $win,
        $menu->{edit}->Append( wxID_FIND, '' ),
        \&Padre::Wx::FindDialog::on_find,
    );
    EVT_MENU( $win,
        $menu->{edit}->Append( -1, "&Find Next\tF3" ),
        \&Padre::Wx::FindDialog::on_find_next,
    );
    EVT_MENU( $win,
        $menu->{edit}->Append( -1, "Find Previous\tShift-F3" ),
        \&Padre::Wx::FindDialog::on_find_previous,
    );
    EVT_MENU( $win,
        $menu->{edit}->Append( -1, "Ac&k" ),
        \&Padre::Wx::Ack::on_ack,
    );
    EVT_MENU( $win,
        $menu->{edit}->Append( -1, "&Goto\tCtrl-G" ),
        \&Padre::Wx::GoToLine::on_goto,
    );
    EVT_MENU( $win,
        $menu->{edit}->Append( -1, "&AutoComp\tCtrl-P" ),
        \&Padre::Wx::MainWindow::on_autocompletition,
    );
    EVT_MENU( $win,
        $menu->{edit}->Append( -1, "Subs\tAlt-S" ),
        sub { $_[0]->{rightbar}->SetFocus },
    ); 
    EVT_MENU( $win,
        $menu->{edit}->Append( -1, "&Brace matching\tCtrl-1" ),
        \&Padre::Wx::MainWindow::on_brace_matching,
    );
    $menu->{edit}->AppendSeparator;

    # User Preferences
    EVT_MENU( $win,
        $menu->{edit}->Append( -1, "&Preferences" ),
        \&Padre::Wx::MainWindow::on_preferences,
    );





    # Create the View menu
    $menu->{view}       = Wx::Menu->new;
    $menu->{view_lines} = $menu->{view}->AppendCheckItem( -1, "Show Line numbers" );
    EVT_MENU( $win,
        $menu->{view_lines},
        \&Padre::Wx::MainWindow::on_toggle_line_numbers,
    );
    $menu->{view_eol} = $menu->{view}->AppendCheckItem( -1, "Show Newlines" );
    EVT_MENU( $win,
        $menu->{view_eol},
        \&Padre::Wx::MainWindow::on_toggle_eol,
    );
    $menu->{view_output} = $menu->{view}->AppendCheckItem( -1, "Show Output" );
    EVT_MENU( $win,
        $menu->{view_output},
        \&Padre::Wx::MainWindow::on_toggle_show_output,
    );
    unless ( Padre::Util::WIN32 ) {
        # On Windows disabling the status bar is broken, so don't allow it
        $menu->{view_statusbar} = $menu->{view}->AppendCheckItem( -1, "Show StatusBar" );
        EVT_MENU( $win,
            $menu->{view_statusbar},
            \&Padre::Wx::MainWindow::on_toggle_status_bar,
        );
    }
    $menu->{view_indentation_guide} = $menu->{view}->AppendCheckItem( -1, "Show Indentation Guide" );
    EVT_MENU( $win,
        $menu->{view_indentation_guide},
        \&Padre::Wx::MainWindow::on_toggle_indentation_guide,
    );
    $menu->{view_show_calltips} = $menu->{view}->AppendCheckItem( -1, "Show Call Tips" );
    EVT_MENU( $win,
        $menu->{view_show_calltips},
        sub { $config->{editor}->{show_calltips} = $menu->{view_show_calltips}->IsChecked },
    );
    $menu->{view}->AppendSeparator;
    EVT_MENU( $win,
        $menu->{view}->Append( -1, "Increase Font Size\tCtrl--" ),
        \&Padre::Wx::MainWindow::on_zoom_in,
    );
    EVT_MENU( $win,
        $menu->{view}->Append( -1, "Decrease Font Size\tCtrl-+" ),
        \&Padre::Wx::MainWindow::on_zoom_out,
    );
    EVT_MENU( $win,
        $menu->{view}->Append( -1, "Reset Font Size\tCtrl-/" ),
        \&Padre::Wx::MainWindow::on_zoom_reset,
    );
    $menu->{view}->AppendSeparator;
    EVT_MENU( $win,
        $menu->{view}->Append( -1, "Set Bookmark\tCtrl-B" ),
        \&Padre::Wx::Bookmarks::on_set_bookmark,
    );
    EVT_MENU( $win,
        $menu->{view}->Append( -1, "Goto Bookmark\tCtrl-Shift-B" ),
        \&Padre::Wx::Bookmarks::on_goto_bookmark,
    );




	# Create the Perl menu
	$menu->{perl} = Wx::Menu->new;

	# Perl-Specific Searches
	$menu->{perl_find_unmatched} = $menu->{perl}->Append( -1, "Find Unmatched Brace" );
	EVT_MENU( $win,
		$menu->{perl_find_unmatched},
		sub {
			my $doc = Padre::Document->from_selection;
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
				Wx::MessageBox( "All braces appear to be matched", "Check Complete", wxOK, $win );
			}
		},
	);
	$menu->{perl}->AppendSeparator;

	# Script Execution
	$menu->{perl_run_script} = $menu->{perl}->Append( -1, "Run Script\tF5" );
	EVT_MENU( $win,
		$menu->{perl_run_script},
		\&Padre::Wx::Execute::on_run_this,
	);
	$menu->{perl_run_command} = $menu->{perl}->Append( -1, "Run Command\tCtrl-F5" );
	EVT_MENU( $win,
		$menu->{perl_run_command},
		\&Padre::Wx::Execute::on_run,
	);
	$menu->{perl_stop} = $menu->{perl}->Append( -1, "&Stop" );
	EVT_MENU( $win,
		$menu->{perl_stop},
		\&Padre::Wx::Execute::on_stop,
	);
	$menu->{perl_stop}->Enable(0);
	EVT_MENU( $win,
		$menu->{perl}->Append( -1, "&Setup" ),
		\&Padre::Wx::Execute::on_setup_run,
	);
	$menu->{perl}->AppendSeparator;

	# Commenting
	EVT_MENU( $win,
		$menu->{perl}->Append( -1, "&Comment Selected Lines\tCtrl-M" ),
		\&Padre::Wx::MainWindow::on_comment_out_block,
	);
	EVT_MENU( $win,
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
	EVT_MENU( $win,
		$menu->{window}->Append( -1, "&Split window" ),
		\&Padre::Wx::MainWindow::on_split_window,
	);
	$menu->{window}->AppendSeparator;
	EVT_MENU( $win,
		$menu->{window}->Append(-1, "Next File\tCtrl-TAB"),
		\&Padre::Wx::MainWindow::on_next_pane,
	);
	EVT_MENU( $win,
		$menu->{window}->Append(-1, "Previous File\tCtrl-Shift-TAB"),
		\&Padre::Wx::MainWindow::on_prev_pane,
	);
	$menu->{window}->AppendSeparator;





	# Create the help menu
	$menu->{help} = Wx::Menu->new;
	EVT_MENU( $win,
		$menu->{help}->Append( wxID_HELP, '' ),
		\&Padre::Wx::Help::on_help,
	);
	EVT_MENU( $win,
		$menu->{help}->Append( -1, "Context Help\tCtrl-Shift-H" ),
		\&Padre::Wx::Help::on_context_help,
	);
	$menu->{help}->AppendSeparator;
	EVT_MENU( $win,
		$menu->{help}->Append( wxID_ABOUT,   '' ),
		\&Padre::Wx::Help::on_about,
	);





    # Create the Experimental menu
    # All the crap that doesn't work, have a home,
    # or should never be seen be real users goes here.
    if ( $experimental ) {
        $menu->{experimental} = Wx::Menu->new;
        EVT_MENU( $win,
            $menu->{experimental}->Append( -1, 'Reflow Menu/Toolbar' ),
            sub {
                $DB::single = 1;
                my $document = Padre::Document->from_selection;
                $_[0]->{menu}->refresh( $document );
                $_[0]->SetMenuBar( $_[0]->{menu}->{wx} );
                $_[0]->GetToolBar->refresh( $document );
                return;
            },
        );
        EVT_MENU(
            $win,
            $menu->{experimental}->Append( -1, 'Run in &Padre' ),
            sub {
                my $self = shift;
                my $code = Padre::Document->from_selection->text_get;
                eval $code;
                if ($@) {
                    Wx::MessageBox("Error: $@", "Self error", wxOK, $self);
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
    $menu->{wx}->Append( $menu->{perl},     "Perl"       );
    $menu->{wx}->Append( $menu->{bookmark}, "&Bookmarks" );
    $menu->{wx}->Append( $menu->{plugin},   "Pl&ugins"   ) if $menu->{plugin};
    $menu->{wx}->Append( $menu->{window},   "&Window"    );
    $menu->{wx}->Append( $menu->{help},     "&Help"      );
    if ( $experimental ) {
        $menu->{wx}->Append( $menu->{experimental}, "E&xperimental" );
    }

    # Setup menu state from configuration
    $menu->{view_lines}->Check( $config->{show_line_numbers} ? 1 : 0 );
    $menu->{view_eol}->Check( $config->{show_eol} ? 1 : 0 );
    unless ( Padre::Util::WIN32 ) {
        $menu->{view_statusbar}->Check( $config->{show_status_bar} ? 1 : 0 );
    }
    $menu->{view_indentation_guide}->Check( $config->{editor}->{indentation_guide} ? 1 : 0 );
    $menu->{view_show_calltips}->Check( $config->{editor}->{show_calltips} ? 1 : 0 );

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
			EVT_MENU( $self->win, $menu->Append(-1, $m->[0]), $m->[1] );
		}
	}

	return $menu;
}

sub add_alt_n_menu {
	my ($self, $file, $n) = @_;
	return if $n > 9;

	$self->{alt}->[$n] = $self->{window}->Append(-1, "");
	EVT_MENU( $self->win, $self->{alt}->[$n], sub { $_[0]->on_nth_pane($n) } );
	$self->update_alt_n_menu($file, $n);

	return;
}

sub update_alt_n_menu {
	my ($self, $file, $n) = @_;

	my $v = $n + 1;
# TODO: fix the occassional crash here:
if (not defined $self->{alt}->[$n]) {
    warn $n;
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
	my $document = _INSTANCE(shift, 'Padre::Document');

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
	if ( $self->{plugins} ) {
		$self->{wx}->Append( $self->{plugin}, "Pl&ugins" );
	}
	$self->{wx}->Append( $self->{window},   "&Window"    );
	$self->{wx}->Append( $self->{help},     "&Help"      );
    if ( Padre->ide->config->{experimental} ) {
        $self->{wx}->Append( $self->{experimental}, "E&xperimental" );
    }

	return 1;
}

1;
