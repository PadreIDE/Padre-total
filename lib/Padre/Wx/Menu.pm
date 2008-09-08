package Padre::Wx::Menu;

use strict;
use warnings;

use Wx        qw(:everything);
use Wx::Event qw(:everything);

our $VERSION = '0.07';





#####################################################################
# Construction and Setup

sub new {
    my ($class, $win) = @_;

    my $ide      = Padre->ide;
    my $config   = $ide->get_config;
    my $menu     = bless {}, $class;

    $menu->{win} = $win;

    # Create the File menu
    $menu->{file} = Wx::Menu->new;
    EVT_MENU( $win, $menu->{file}->Append( wxID_NEW,  '' ), \&Padre::Wx::MainWindow::on_new  );
    EVT_MENU( $win, $menu->{file}->Append( wxID_OPEN, '' ), \&Padre::Wx::MainWindow::on_open );
    EVT_MENU( $win, $menu->{file}->Append( -1, "Open Selection\tCtrl-Shift-O" ),  \&Padre::Wx::MainWindow::on_open_selection);
    $menu->{file_recent} = Wx::Menu->new;
    $menu->{file}->Append( -1, "Recent Files", $menu->{file_recent} );
    foreach my $f ( $ide->get_recent('files') ) {
       EVT_MENU(
           $win,
           $menu->{file_recent}->Append(-1, $f), 
           sub { $_[0]->setup_editor($f) },
       );
    }
    EVT_MENU( $win, $menu->{file}->Append( wxID_SAVE,   '' ), \&Padre::Wx::MainWindow::on_save     );
    EVT_MENU( $win, $menu->{file}->Append( wxID_SAVEAS, '' ), \&Padre::Wx::MainWindow::on_save_as  );
    EVT_MENU( $win, $menu->{file}->Append( -1, 'Save All'  ), \&Padre::Wx::MainWindow::on_save_all );
    EVT_MENU( $win, $menu->{file}->Append( wxID_CLOSE,  '' ), \&Padre::Wx::MainWindow::on_close    );
    EVT_MENU( $win, $menu->{file}->Append( -1, 'Close All' ), \&Padre::Wx::MainWindow::on_close_all );
    EVT_MENU( $win, $menu->{file}->Append( wxID_EXIT,   '' ), \&Padre::Wx::MainWindow::on_exit     );

    # Create the Project menu
    #$menu->{project} = Wx::Menu->new;
    #EVT_MENU( $win, $menu->{project}->Append( -1, "&New"),        \&Padre::Wx::MainWindow::on_new_project );
    #EVT_MENU( $win, $menu->{project}->Append( -1, "&Select"    ), \&Padre::Wx::MainWindow::on_select_project );





    # Create the Edit menu
    $menu->{edit} = Wx::Menu->new;
    EVT_MENU( $win, $menu->{edit}->Append( wxID_UNDO, '' ),                \&Padre::Wx::MainWindow::on_undo             );
    EVT_MENU( $win, $menu->{edit}->Append( wxID_REDO, "\tCtrl-Shift-Z" ),  \&Padre::Wx::MainWindow::on_redo             );
    EVT_MENU( $win, $menu->{edit}->Append( wxID_FIND, '' ),           \&Padre::Wx::MainWindow::on_find             );
    EVT_MENU( $win, $menu->{edit}->Append( -1, "&Find Again\tF3" ),   \&Padre::Wx::MainWindow::on_find_again       );
    EVT_MENU( $win, $menu->{edit}->Append( -1, "Ac&k" ),              \&Padre::Wx::Ack::on_ack  );
    EVT_MENU( $win, $menu->{edit}->Append( -1, "&Goto\tCtrl-G" ),     \&Padre::Wx::MainWindow::on_goto             );
    EVT_MENU( $win, $menu->{edit}->Append( -1, "&AutoComp\tCtrl-P" ), \&Padre::Wx::MainWindow::on_autocompletition );
    EVT_MENU( $win, $menu->{edit}->Append( -1, "Subs\tAlt-S"     ),   sub { $_[0]->{rightbar}->SetFocus()} ); 
    EVT_MENU( $win, $menu->{edit}->Append( -1, "&Comment out block\tCtrl-M" ),   \&Padre::Wx::MainWindow::on_comment_out_block       );
    EVT_MENU( $win, $menu->{edit}->Append( -1, "&UnComment block\tCtrl-Shift-M" ),   \&Padre::Wx::MainWindow::on_uncomment_block       );
    EVT_MENU( $win, $menu->{edit}->Append( -1, "&Brace matching\tCtrl-B" ),   \&Padre::Wx::MainWindow::on_brace_matching       );
    EVT_MENU( $win, $menu->{edit}->Append( -1, "&Split window" ),   \&Padre::Wx::MainWindow::on_split_window     );
    EVT_MENU( $win, $menu->{edit}->Append( -1, "&Setup" ),            \&Padre::Wx::MainWindow::on_setup            );

    $menu->{edit_convert} = Wx::Menu->new;
    $menu->{edit}->Append( -1, "Convert File", $menu->{edit_convert} );
    foreach my $os ( qw(UNIX MAC WIN) ) {
       EVT_MENU(
           $win,
           $menu->{edit_convert}->Append(-1, "to $os"), 
           sub { $_[0]->convert_to($os) },
       );
    }




    # Create the View menu
    $menu->{view}       = Wx::Menu->new;
    $menu->{view_lines} = $menu->{view}->AppendCheckItem( -1, "Show Line numbers" );
    $menu->{view_lines}->Check( $config->{show_line_numbers} ? 1 : 0 );
    EVT_MENU(
        $win,
        $menu->{view_lines},
        \&Padre::Wx::MainWindow::on_toggle_line_numbers,
    );
    $menu->{view_eol} = $menu->{view}->AppendCheckItem( -1, "Show Newlines" );
    $menu->{view_eol}->Check( $config->{show_eol} ? 1 : 0 );
    EVT_MENU(
        $win,
        $menu->{view_eol},
        \&Padre::Wx::MainWindow::on_toggle_eol,
    );
    $menu->{view_output} = $menu->{view}->AppendCheckItem( -1, "Show Output" );
    EVT_MENU(
        $win,
        $menu->{view_output},
        \&Padre::Wx::MainWindow::on_toggle_show_output,
    );
    $menu->{view_statusbar} = $menu->{view}->AppendCheckItem( -1, "Show StatusBar" );
    $menu->{view_statusbar}->Check( $config->{show_status_bar} ? 1 : 0 );
    EVT_MENU(
        $win,
        $menu->{view_statusbar},
        \&Padre::Wx::MainWindow::on_toggle_status_bar,
    );
    $menu->{view_indentation_guide} = $menu->{view}->AppendCheckItem( -1, "Show Indentation Guide" );
    $menu->{view_indentation_guide}->Check( $config->{editor}->{indentation_guide} ? 1 : 0 );
    EVT_MENU(
        $win,
        $menu->{view_indentation_guide},
        \&Padre::Wx::MainWindow::on_toggle_indentation_guide,
    );
    EVT_MENU( $win, $menu->{view}->Append( -1, "&Zoom in\tCtrl--" ),   \&Padre::Wx::MainWindow::on_zoom_in   );
    EVT_MENU( $win, $menu->{view}->Append( -1, "&Zoom out\tCtrl-+" ),  \&Padre::Wx::MainWindow::on_zoom_out  );
    EVT_MENU( $win, $menu->{view}->Append( -1, "&Zoom reset\tCtrl-/" ),  \&Padre::Wx::MainWindow::on_zoom_reset  );

    $menu->{view}->AppendSeparator;
    #$menu->{view_files} = Wx::Menu->new;
    #$menu->{view}->Append( -1, "Switch to...", $menu->{view_files} );
    EVT_MENU(
        $win,
        $menu->{view}->Append(-1, "Next File\tCtrl-TAB"),
        \&Padre::Wx::MainWindow::on_next_pane,
    );
    EVT_MENU(
        $win,
        $menu->{view}->Append(-1, "Prev File\tCtrl-Shift-TAB"),
        \&Padre::Wx::MainWindow::on_prev_pane,
    );





    # Creat the Run menu
    $menu->{run} = Wx::Menu->new;
    $menu->{run_this} = $menu->{run}->Append( -1, "Run &This\tF5" );
    EVT_MENU(
        $win,
        $menu->{run_this},
        \&Padre::Wx::Execute::on_run_this,
    );
    $menu->{run_any} = $menu->{run}->Append( -1, "Run Any\tCtrl-F5" );
    EVT_MENU(
        $win,
        $menu->{run_any},
        \&Padre::Wx::Execute::on_run,
    );
    $menu->{run_stop} = $menu->{run}->Append( -1, "&Stop" );
    EVT_MENU(
        $win,
        $menu->{run_stop},
        \&Padre::Wx::Execute::on_stop,
    );
    EVT_MENU(
        $win,
        $menu->{run}->Append( -1, "&Setup" ),
        \&Padre::Wx::Execute::on_setup_run,
    );
    $menu->{run_stop}->Enable(0);

    
    # Create the Plugins menu
    $menu->{plugin} = Wx::Menu->new;
    my %plugins = %{ $ide->plugin_manager->plugins };
    foreach my $name ( sort keys %plugins ) {
        next if not $plugins{$name};
        my @menu    = eval { $plugins{$name}->menu };
        warn "Error when calling menu for plugin '$name' $@" if $@;
        my $menu_items = $menu->add_plugin_menu_items(\@menu);
        $menu->{plugin}->Append( -1, $name, $menu_items );
    }





    # Create the help menu
    $menu->{help} = Wx::Menu->new;
    EVT_MENU(
        $win,
        $menu->{help}->Append( wxID_ABOUT,   '' ),
        \&Padre::Wx::Help::on_about,
    );
    EVT_MENU(
        $win,
        $menu->{help}->Append( wxID_HELP, '' ),
        \&Padre::Wx::Help::on_help,
    );
    EVT_MENU(
        $win,
        $menu->{help}->Append( -1, "Context-help\tCtrl-Shift-H" ),
        \&Padre::Wx::Help::on_context_help,
    );





    # Create the Experimental menu
    $menu->{experimental} = Wx::Menu->new;
    EVT_MENU(
        $win,
        $menu->{experimental}->Append( -1, 'Reflow Menu' ),
        sub {
            $DB::single = 1;
            $_[0]->{menu}->reflow;
        },
    );





    # Create and return the main menu bar
    $menu->{wx} = Wx::MenuBar->new;
    $menu->{wx}->Append( $menu->{file},    "&File" );
    $menu->{wx}->Append( $menu->{project}, "&Project" );
    $menu->{wx}->Append( $menu->{edit},    "&Edit" );
    $menu->{wx}->Append( $menu->{view},    "&View" );
    $menu->{wx}->Append( $menu->{run},     "&Run" );
    if ( %plugins ) {
        $menu->{wx}->Append( $menu->{plugin}, "Pl&ugins" );
    }
    $menu->{wx}->Append( $menu->{help},    "&Help" );
    # $menu->{wx}->Append( $menu->{experimental}, "E&xperimental" );

    # Do an initial reflow
    # $menu->reflow;

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

    $self->{alt}->[$n] = $self->{view}->Append(-1, "");
    EVT_MENU( $self->win, $self->{alt}->[$n], sub {$_[0]->on_nth_pane($n)} );
    $self->update_alt_n_menu($file, $n);

    return;
}

sub update_alt_n_menu {
    my ($self, $file, $n) = @_;

    my $v = $n +1;
    $self->{alt}->[$n]->SetText("$file\tAlt-$v");

    return;
}

sub remove_alt_n_menu {
    my ($self) = @_;

    $self->{view}->Remove(pop @{ $self->{alt} });

    return;
}

sub win {
	$_[0]->{win};
}





#####################################################################
# Reflowing the Menu

sub reflow {
	my $self  = shift;
	my $lexer = $self->win->get_current_editor->GetLexer;

	# Enable or disable the run menu
	if ( $lexer == wxSTC_LEX_PERL ) {
		$self->{wx}->EnableTop( 4, 1 );
	} else {
		$self->{wx}->EnableTop( 4, 0 );
	}

	return 1;
}

1;
