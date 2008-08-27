package Padre::Wx::MainWindow;

use strict;
use warnings;
use English        qw(-no_match_vars);
use FindBin;
use Carp           ();
use File::Spec     ();
use File::Slurp    ();
use File::Basename ();
use Data::Dumper   ();
use List::Util     ();
use File::ShareDir ();
use Wx                      qw(:everything);
use Wx::Event               qw(:everything);
use Wx::Perl::ProcessStream qw(:everything);

use base 'Wx::Frame';

use Padre::Wx::Text;
use Padre::Wx::FindDialog;
use Padre::Pod::Frame;

our $VERSION = '0.06';

my $default_dir = "";
my $cnt         = 0;

use vars qw{%SYNTAX};
BEGIN {
	# see Wx-0.84/ext/stc/cpp/st_constants.cpp for extension
	# N.B. Some constants (wxSTC_LEX_ESCRIPT for example) are defined in 
	#  wxWidgets-2.8.7/contrib/include/wx/stc/stc.h 
	# but not (yet) in 
	#  Wx-0.84/ext/stc/cpp/st_constants.cpp
	# so we have to hard-code their numeric value.
	%SYNTAX = (
		ada   => wxSTC_LEX_ADA,
		asm   => wxSTC_LEX_ASM,
		# asp => wxSTC_LEX_ASP, #in ifdef
		bat   => wxSTC_LEX_BATCH,
		cpp   => wxSTC_LEX_CPP,
		css   => wxSTC_LEX_CSS,
		diff  => wxSTC_LEX_DIFF,
		#     => wxSTC_LEX_EIFFEL, # what is the default EIFFEL file extension?
		#     => wxSTC_LEX_EIFFELKW,
		'4th' => wxSTC_LEX_FORTH,
		f     => wxSTC_LEX_FORTRAN,
		html  => wxSTC_LEX_HTML,
		js    => 41, # wxSTC_LEX_ESCRIPT (presumably "ESCRIPT" refers to ECMA-script?) 
		json  => 41, # wxSTC_LEX_ESCRIPT (presumably "ESCRIPT" refers to ECMA-script?)
		latex => wxSTC_LEX_LATEX,
		lsp   => wxSTC_LEX_LISP,
		lua   => wxSTC_LEX_LUA,
		mak   => wxSTC_LEX_MAKEFILE,
		mat   => wxSTC_LEX_MATLAB,
		pas   => wxSTC_LEX_PASCAL,
		pl    => wxSTC_LEX_PERL,
		pod   => wxSTC_LEX_PERL,
		pm    => wxSTC_LEX_PERL,
		php   => wxSTC_LEX_PHPSCRIPT,
		py    => wxSTC_LEX_PYTHON,
		rb    => wxSTC_LEX_RUBY,
		sql   => wxSTC_LEX_SQL,
		tcl   => wxSTC_LEX_TCL,
		t     => wxSTC_LEX_PERL,
		yml   => wxSTC_LEX_YAML,
		yaml  => wxSTC_LEX_YAML,
		vbs   => wxSTC_LEX_VBSCRIPT,
		#     => wxSTC_LEX_VB, # What's the difference between VB and VBSCRIPT?
		xml   => wxSTC_LEX_XML,
		_default_ => wxSTC_LEX_AUTOMATIC,
	);
}


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
        'Padre ',
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
    $self->{menu} = $self->_create_menu_bar;
    $self->SetMenuBar( $self->{menu}->{wx} );

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
    EVT_LIST_ITEM_SELECTED(
        $self,
        $self->{rightbar},
        \&method_selected,
    );
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
    EVT_WXP_PROCESS_STREAM_STDOUT( $self, \&evt_process_stdout );
    EVT_WXP_PROCESS_STREAM_STDERR( $self, \&evt_process_stderr );
    EVT_WXP_PROCESS_STREAM_EXIT( $self, \&evt_process_exit );

    # Load any default files
    $self->_load_files;

    return $self;
}

sub _add_alt_n_menu {
    my ($self, $file, $n) = @_;
    return if $n > 9;

    $self->{menu}->{alt}->[$n] = $self->{menu}->{view}->Append(-1, "");
    EVT_MENU( $self, $self->{menu}->{alt}->[$n], sub {$_[0]->on_nth_pane($n)} );
    $self->_update_alt_n_menu($file, $n);

    return;
}

sub _update_alt_n_menu {
    my ($self, $file, $n) = @_;

    my $v = $n +1;
    $self->{menu}->{alt}->[$n]->SetText("$file\tAlt-$v");

    return;
}

sub _remove_alt_n_menu {
    my ($self) = @_;

    $self->{menu}->{view}->Remove(pop @{ $self->{menu}->{alt} });

    return;
}

sub _create_menu_bar {
    my $self   = shift;
    my $ide    = Padre->ide;
    my $config = $ide->get_config;
    my $menu   = {};

    # Create the File menu
    $menu->{file} = Wx::Menu->new;
    EVT_MENU( $self, $menu->{file}->Append( wxID_NEW,  '' ), \&on_new  );
    EVT_MENU( $self, $menu->{file}->Append( wxID_OPEN, '' ), \&on_open );
    $menu->{file_recent} = Wx::Menu->new;
    $menu->{file}->Append( -1, "Recent Files", $menu->{file_recent} );
    foreach my $f ( $ide->get_recent('files') ) {
       EVT_MENU(
           $self,
           $menu->{file_recent}->Append(-1, $f), 
           sub { $_[0]->setup_editor($f) },
       );
    }
    EVT_MENU( $self, $menu->{file}->Append( wxID_SAVE,   '' ), \&on_save     );
    EVT_MENU( $self, $menu->{file}->Append( wxID_SAVEAS, '' ), \&on_save_as  );
    EVT_MENU( $self, $menu->{file}->Append( -1, 'Save All'  ), \&on_save_all );
    EVT_MENU( $self, $menu->{file}->Append( wxID_CLOSE,  '' ), \&on_close    );
    EVT_MENU( $self, $menu->{file}->Append( wxID_EXIT,   '' ), \&on_exit     );



    # Create the Project menu
    $menu->{project} = Wx::Menu->new;
    EVT_MENU( $self, $menu->{project}->Append( -1, "&New"), \&on_new_project );
    EVT_MENU( $self, $menu->{project}->Append( -1, "&Select"    ), \&on_select_project );



    # Create the Edit menu
    $menu->{edit} = Wx::Menu->new;
    EVT_MENU( $self, $menu->{edit}->Append( wxID_UNDO, '' ),           \&on_undo             );
    EVT_MENU( $self, $menu->{edit}->Append( wxID_REDO, "\tCtrl-Shift-Z" ),  \&on_redo             );
    EVT_MENU( $self, $menu->{edit}->Append( wxID_FIND, '' ),           \&on_find             );
    EVT_MENU( $self, $menu->{edit}->Append( -1, "&Find Again\tF3" ),   \&on_find_again       );
    EVT_MENU( $self, $menu->{edit}->Append( -1, "&Goto\tCtrl-G" ),     \&on_goto             );
    EVT_MENU( $self, $menu->{edit}->Append( -1, "&AutoComp\tCtrl-P" ), \&on_autocompletition );
    EVT_MENU( $self, $menu->{edit}->Append( -1, "Subs\tAlt-S"     ),   sub { $_[0]->{rightbar}->SetFocus()} ); 
    EVT_MENU( $self, $menu->{edit}->Append( -1, "&Comment out block\tCtrl-M" ),   \&on_comment_out_block       );
    EVT_MENU( $self, $menu->{edit}->Append( -1, "&UnComment block\tCtrl-Shift-M" ),   \&on_uncomment_block       );
    EVT_MENU( $self, $menu->{edit}->Append( -1, "&Brace matching\tCtrl-B" ),   \&on_brace_matching       );

    EVT_MENU( $self, $menu->{edit}->Append( -1, "&Setup" ),            \&on_setup            );



    # Create the View menu
    $menu->{view}       = Wx::Menu->new;
    $menu->{view_lines} = $menu->{view}->AppendCheckItem( -1, "Show Line numbers" );
    $menu->{view_lines}->Check( $config->{show_line_numbers} ? 1 : 0 );
    EVT_MENU(
        $self,
        $menu->{view_lines},
        \&on_toggle_line_numbers,
    );
    $menu->{view_eol} = $menu->{view}->AppendCheckItem( -1, "Show Newlines" );
    $menu->{view_eol}->Check( $config->{show_eol} ? 1 : 0 );
    EVT_MENU(
        $self,
        $menu->{view_eol},
        \&on_toggle_eol,
    );
    $menu->{view_output} = $menu->{view}->AppendCheckItem( -1, "Show Output" );
    EVT_MENU(
        $self,
        $menu->{view_output},
        \&on_toggle_show_output,
    );
    $menu->{view_statusbar} = $menu->{view}->AppendCheckItem( -1, "Show StatusBar" );
    $menu->{view_statusbar}->Check( $config->{show_statusbar} ? 1 : 0 );
    EVT_MENU(
        $self,
        $menu->{view_statusbar},
        \&on_toggle_status_bar,
    );

    $menu->{view}->AppendSeparator;
    #$menu->{view_files} = Wx::Menu->new;
    #$menu->{view}->Append( -1, "Switch to...", $menu->{view_files} );
    EVT_MENU(
        $self,
        $menu->{view}->Append(-1, "Next File\tCtrl-TAB"),
        \&on_next_pane,
    );
    EVT_MENU(
        $self,
        $menu->{view}->Append(-1, "Prev File\tCtrl-Shift-TAB"),
        \&on_prev_pane,
    );

    # Creat the Run menu
    $menu->{run} = Wx::Menu->new;
    $menu->{run_this} = $menu->{run}->Append( -1, "Run &This\tF5" );
    EVT_MENU(
        $self,
        $menu->{run_this},
        \&on_run_this,
    );
    $menu->{run_any} = $menu->{run}->Append( -1, "Run Any\tCtrl-F5" );
    EVT_MENU(
        $self,
        $menu->{run_any},
        \&on_run,
    );
    $menu->{run_stop} = $menu->{run}->Append( -1, "&Stop" );
    EVT_MENU(
        $self,
        $menu->{run_stop},
        \&on_stop,
    );
    EVT_MENU(
        $self,
        $menu->{run}->Append( -1, "&Setup" ),
        \&on_setup_run,
    );
    $menu->{run_stop}->Enable(0);

    
    # Create the Plugins menu
    $menu->{plugin} = Wx::Menu->new;
    my %plugins = %{ $ide->{plugins} };
    foreach my $name ( sort keys %plugins ) {
        next if not $plugins{$name};
        my @menu    = eval { $plugins{$name}->menu };
        warn "Error when calling menu for plugin '$name' $@" if $@;
        my $menu_items = $self->_add_plugin_menu_items(\@menu);
        $menu->{plugin}->Append( -1, $name, $menu_items );
    }



    # Create the help menu
    $menu->{help} = Wx::Menu->new;
    EVT_MENU(
        $self,
        $menu->{help}->Append( wxID_ABOUT,   '' ),
        \&on_about,
    );
    EVT_MENU(
        $self,
        $menu->{help}->Append( wxID_HELP, '' ),
        \&on_help,
    );
    EVT_MENU(
        $self,
        $menu->{help}->Append( -1, "Context-help\tCtrl-Shift-H" ),
        \&on_context_help,
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

    return $menu;
}


# Recursively add plugin menu items from nested array refs
sub _add_plugin_menu_items {
    my ($self, $menu_items) = @_;

    my $menu = Wx::Menu->new;
    foreach my $m ( @{$menu_items} ) {
        if (ref $m->[1] eq 'ARRAY') {
            my $submenu = $self->_add_plugin_menu_items($m->[1]);
            $menu->Append(-1, $m->[0], $submenu);
        } else {
            EVT_MENU( $self, $menu->Append(-1, $m->[0]), $m->[1] );
        }
    }
    return $menu;
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
    $self->_search(search_term => "sub $sub"); # TODO actually search for sub\s+$sub
    return;
}

sub get_current_editor {
    my $nb = $_[0]->{notebook};
    return $nb->GetPage( $nb->GetSelection );
}

sub get_current_content {
    $_[0]->get_current_editor->GetText;
}

sub _bitmap {
    my $file = shift;
    my $dir  = $ENV{PADRE_DEV}
        ? File::Spec->catdir($FindBin::Bin, '..', 'share')
        : File::ShareDir::dist_dir('Padre');
    my $path = File::Spec->catfile($dir , 'docview', "$file.xpm");
    return Wx::Bitmap->new( $path, wxBITMAP_TYPE_XPM );
}

sub on_key {
    my ($self, $event) = @_;

    $self->update_status;

    my $mod  = $event->GetModifiers() || 0;
    my $code = $event->GetKeyCode;
    #print "$mod $code\n";
    if ($mod == 2) {            # Ctrl
        if (57 >= $code and $code >= 49) {       # Ctrl-1-9
            $self->on_set_mark($event, $code - 49);
        } elsif ($code == WXK_TAB) {              # Ctrl-TAB  #TODO why do we still need this?
            $self->on_next_pane;
        }
    } elsif ($mod == 6) {                         # Ctrl-Shift
        if ($code == WXK_TAB) {              # Ctrl-Shift-TAB
            $self->on_prev_pane;
        } elsif (57 >= $code and $code >= 49) {   # Ctrl-Shift-1-9      go to marker $id\n";
            $self->on_jumpto_mark($event, $code - 49);
        }
    }

    return;
}

sub on_set_mark {
    my ($self, $event, $id) = @_;
    my $pageid = $self->{notebook}->GetSelection();
    my $page = $self->{notebook}->GetPage($pageid);
    my $line = $page->GetCurrentLine;
    $self->{marker}->{$id} = $line;
}

sub on_jumpto_mark {
    my ($self, $event, $id) = @_;
    my $pageid = $self->{notebook}->GetSelection();
    my $page = $self->{notebook}->GetPage($pageid);
    if (defined $self->{marker}->{$id}) {
        $page->GotoLine($self->{marker}->{$id});
    }
}

sub on_brace_matching {
    my ($self, $event) = @_;
    my $id   = $self->{notebook}->GetSelection;
    my $page = $self->{notebook}->GetPage($id);
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
}


sub on_comment_out_block {
    my ($self, $event) = @_;

    my $pageid = $self->{notebook}->GetSelection();
    my $page = $self->{notebook}->GetPage($pageid);
    my $start = $page->LineFromPosition($page->GetSelectionStart);
    my $end = $page->LineFromPosition($page->GetSelectionEnd);

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
    my $page = $self->{notebook}->GetPage($pageid);
    my $start = $page->LineFromPosition($page->GetSelectionStart);
    my $end = $page->LineFromPosition($page->GetSelectionEnd);

    $page->BeginUndoAction;
    for my $line ($start .. $end) {
        # TODO: this should actually depend on language
        my $first = $page->PositionFromLine($line);
        my $last = $first+1;
        my $text = $page->GetTextRange($first, $last);
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
   my $id     = $self->{notebook}->GetSelection;
   my $page   = $self->{notebook}->GetPage($id);
   my $pos    = $page->GetCurrentPos;
   my $line   = $page->LineFromPosition($pos);
   my $first  = $page->PositionFromLine($line);
   my $prefix = $page->GetTextRange($first, $pos); # line from beginning to current position
      $prefix =~ s{^.*?((\w+::)*\w+)$}{$1};
   my $last   = $page->GetLength();
   my $text   = $page->GetTextRange(0, $last);
   my %seen;
   my @words = grep { ! $seen{$_}++ } sort ($text =~ m{\b($prefix\w*(?:::\w+)*)\b}g);
   if (@words > 20) {
      @words = @words[0..19];
   }
   $page->AutoCompShow(length($prefix), join " ", @words);
   return;
}

sub on_right_click {
    my ($self, $event) = @_;
    print "right\n";
    my @options = qw(abc def);
    my $HEIGHT = 30;
    my $dialog = Wx::Dialog->new( $self, -1, "", [-1, -1], [100, 50 + $HEIGHT * $#options], wxBORDER_SIMPLE);
    #$dialog->;
    foreach my $i (0..@options-1) {
        EVT_BUTTON( $dialog, Wx::Button->new( $dialog, -1, $options[$i], [10, 10+$HEIGHT*$i] ), sub {on_right(@_, $i)} );
    }
    my $ret = $dialog->Show;
    print "ret\n";
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
    print "$self $event $val\n";
    #print ">", $event->GetClientObject, "<\n";
    $self->Hide;
    $self->Destroy;
}

sub on_exit {
    my ($self) = @_;
    $self->Close
}

sub on_close_window {
    my ( $self, $event ) = @_;
    my $config = Padre->ide->get_config;

    # Check that all files have been saved
    if ( $event->CanVeto ) {
        my @unsaved;
        foreach my $id (0 .. $self->{notebook}->GetPageCount -1) {
            if ( $self->_buffer_changed($id) ) {
                push @unsaved, $self->{notebook}->GetPageText($id);
            }
        }
        if (@unsaved) {
            Wx::MessageBox( "The following buffers are still not saved:\n" . join("\n", @unsaved), 
                            "Unsaved", wxOK|wxCENTRE, $self );
            $event->Veto;
            return;
        }

        my @files = map { scalar $self->_get_filename($_) } ( 0 .. $self->{notebook}->GetPageCount - 1 );
        $config->{main}->{files} = \@files;
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
}

sub _lexer {
    my ($file) = @_;
    return $SYNTAX{_default_} if not $file;
    (my $ext = $file) =~ s{.*\.}{};
    $ext = lc $ext;
    return $SYNTAX{_default_} if not $ext;
    return( (defined $SYNTAX{$ext}) ? $SYNTAX{$ext} : $SYNTAX{_default_});
}

# for files without a type
sub _get_default_file_type {
    # TODO: get it from config
    return _get_local_filetype();
}
# Where to convert (UNIX, WIN, MAC)
# or Ask (the user) or Keep (the garbage)
# mixed files
sub _mixed_newlines {
    # TODO get from config
    return _get_local_filetype();
}

# What to do with files that have consistent line endings:
# 0 if keep as they are
# MAC|UNIX|WIN convert them to the appropriate type
sub _auto_convert {
    # TODO get from config
    return 0;
}

sub _get_local_filetype {
    return $^O =~ /MSWin|cygwin|dos|os2/i ? 'WIN' : 
           $^O =~ /MacOS/                 ? 'MAC' : 'UNIX';
}

sub setup_editor {
    my ($self, $file) = @_;

    $self->{_in_setup_editor} = 1;

    # Flush old stuff
    delete $self->{project};

    my $config    = Padre->ide->get_config;
    my $editor    = Padre::Wx::Text->new( $self->{notebook}, _lexer($file) );
    my $file_type = _get_default_file_type();

    my %mode = (
       'WIN'  => Wx::wxSTC_EOL_CRLF,
       'MAC'  => Wx::wxSTC_EOL_CR,
       'UNIX' => Wx::wxSTC_EOL_LF,
    );

    $cnt++;
    my $title   = " Unsaved Document $cnt";
    my $content = '';
    if ($file) {
        my $convert_to;
        $content = eval { File::Slurp::read_file($file) };
        if ($@) {
            warn $@;
            delete $self->{_in_setup_editor};
            return;
        }
        my $current_type = Padre::get_newline_type($content);
        if ($current_type eq 'None') {
            # keep default
        } elsif ($current_type eq 'Mixed') {
            my $mixed = _mixed_newlines();
            if ( $mixed eq 'Ask') {
                warn "TODO ask the user what to do with $file";
                # $convert_to = $file_type = ;
            } elsif ( $mixed eq 'Keep' ) {
                warn "TODO probably we should not allow keeping garbage ($file) \n";
            } else {
                #warn "TODO converting $file";
                $convert_to = $file_type = $mixed;
            }
        } else {
            $convert_to = _auto_convert();
            if ($convert_to) {
                #warn "TODO call converting on $file";
                $file_type = $convert_to;
            } else {
                $file_type = $current_type;
            }
        }
        $editor->SetEOLMode( $mode{$file_type} );

        $title   = File::Basename::basename($file);
        # require Padre::Project;
	# $self->{project} = Padre::Project->from_file($file);
        $editor->SetText( $content );
        $editor->EmptyUndoBuffer;
        if ($convert_to) {
           warn "Converting to $convert_to";
           $editor->ConvertEOLs( $mode{$file_type} );
        }
    }
    _toggle_numbers($editor, $config->{show_line_numbers});
    _toggle_eol($editor, $config->{show_eol});

    $self->{notebook}->AddPage($editor, $title, 1); # TODO add closing x
    $editor->SetFocus;
    my $pack = __PACKAGE__;
    #my $page = $self->{notebook}->GetCurrentPage;
    my $id  = $self->{notebook}->GetSelection;
    $self->_add_alt_n_menu($file, $id);

    $self->_set_filename($id, $file, $file_type);
    #print "x" . $editor->AutoCompActive .  "x\n";

    #$editor->UsePopUp(0);
    #EVT_RIGHT_DOWN( $editor, \&on_right_click );

    #EVT_RIGHT_UP( $self, \&on_right_click );
    #EVT_STC_DWELLSTART( $editor, -1, sub {print 1});
    #EVT_MOTION( $editor, sub {print '.'});

    delete $self->{_in_setup_editor};
    $self->update_status;
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
        _toggle_numbers( $editor, $config->{show_line_numbers} );
    }

    return;
}


sub on_toggle_eol {
    my ($self, $event) = @_;

    my $config = Padre->ide->get_config;
    $config->{show_eol} = $event->IsChecked ? 1 : 0;

    foreach my $id (0 .. $self->{notebook}->GetPageCount -1) {
        my $editor = $self->{notebook}->GetPage($id);
        _toggle_eol($editor, $config->{show_eol})
    }
    return;
}


# currently if there are 9 lines we set the margin to 1 width and then
# if another line is added it is not seen well.
# actually I added some improvement allowing a 50% growth in the file
# and requireing a min of 2 width
sub _toggle_numbers {
    my ($editor, $on) = @_;

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
}
sub _toggle_eol {
    my ($editor, $on) = @_;
    $editor->SetViewEOL($on);
    return;
}


sub on_open {
    my ($self) = @_;

    my $dialog = Wx::FileDialog->new( $self, "Open file", $default_dir, "", "*.*", wxFD_OPEN);
    if ($^O !~ /win32/i) {
       $dialog->SetWildcard("*");
    }
    if ($dialog->ShowModal == wxID_CANCEL) {
        #print "Cancel\n";
        return;
    }
    my $filename = $dialog->GetFilename;
    #print "OK $filename\n";
    $default_dir = $dialog->GetDirectory;

    my $file = File::Spec->catfile($default_dir, $filename);
    Padre->ide->add_to_recent('files', $file);

    # if the current buffer is empty then fill that with the content of the current file
    # otherwise open a new buffer and open the file there
    $self->setup_editor($file);

    return;
}

sub on_new {
    my ($self) = @_;
    $self->setup_editor;
    return;
}

sub _set_filename {
    my ($self, $id, $data, $type) = @_;

    my $pack = __PACKAGE__;
    my $page = $self->{notebook}->GetPage($id);
    $page->{$pack}->{filename} = $data;
    $page->{$pack}->{type}     = $type;

    if ($data) {
       $page->SetLexer( _lexer($data) ); # set the syntax highlighting
       $page->Colourise(0, $page->GetTextLength);
    }

    return;
}

sub _get_filename {
    my ($self, $id) = @_;

    my $pack = __PACKAGE__;
    my $page = $self->{notebook}->GetPage($id);

    
    if (wantarray) {
	return ($page->{$pack}->{filename}, $page->{$pack}->{type});
    } else {
	return $page->{$pack}->{filename};
    }
}

sub _set_page_text {
    my ($self, $id, $text) = @_;

    my $pack = __PACKAGE__;
    my $page = $self->{notebook}->GetPage($id);
    return $page->SetText($text);
}

sub _get_page_text {
    my ($self, $id) = @_;

    my $pack = __PACKAGE__;
    my $page = $self->{notebook}->GetPage($id);
    return $page->GetText;
}


=head2 get_current_filename

Returns the name filename of the current buffer.

=cut

sub get_current_filename {
    my ($self) = @_;
    my $id = $self->{notebook}->GetSelection;
    return $self->_get_filename($id);
}

sub set_page_text {
    my ($self, $text) = @_;
    my $id = $self->{notebook}->GetSelection;
    return $self->_set_page_text($id, $text);
}

sub get_page_text {
    my ($self) = @_;
    my $id = $self->{notebook}->GetSelection;
    return $self->_get_page_text($id);
}

sub on_save_as {
    my ($self) = @_;

    my $id   = $self->{notebook}->GetSelection;
    return if $id == -1;

    while (1) {
        my $dialog = Wx::FileDialog->new( $self, "Save file as...", $default_dir, "", "*.*", wxFD_SAVE);
        if ($dialog->ShowModal == wxID_CANCEL) {
            #print "Cancel\n";
            return;
        }
        my $filename = $dialog->GetFilename;
        #print "OK $filename\n";
        $default_dir = $dialog->GetDirectory;

        my $path = File::Spec->catfile($default_dir, $filename);
        if (-e $path) {
            my $res = Wx::MessageBox("File already exists. Overwrite it?", "Exist", wxYES_NO, $self);
            if ($res == wxYES) {
                $self->_set_filename($id, $path, _get_local_filetype());
                last;
            }
        } else {
            $self->_set_filename($id, $path, _get_local_filetype());
            last;
        }
    }
    $self->_save_buffer($id);
    return;
}

sub on_save {
    my ($self) = @_;
    my $id = $self->{notebook}->GetSelection;
    if ( $id == -1 ) {
        return;
    }
    if ( not $self->_buffer_changed($id) and $self->_get_filename($id) ) {
        return;
    }
    if ($self->_get_filename($id)) {
        $self->_save_buffer($id);
    } else {
        $self->on_save_as();
    }
    return;
}

sub on_save_all {
    my ($self) = @_;
    foreach my $id (0 .. $self->{notebook}->GetPageCount -1) {
        if ( $self->_buffer_changed($id) ) {
            $self->_save_buffer($id);
        }
    }
    return;
}

sub _save_buffer {
    my ($self, $id) = @_;

    my $page = $self->{notebook}->GetPage($id);
    my $content = $page->GetText;
    my ($filename, $file_type) = $self->_get_filename($id);
    eval {
        File::Slurp::write_file($filename, $content);
    };
    Padre->ide->add_to_recent('files', $filename);
    $self->{notebook}->SetPageText($id, File::Basename::basename($filename));
    $page->SetSavePoint;
    $self->update_status;
    $self->update_methods;

    return; 
}

sub on_close {
    my ($self) = @_;
    my $id     = $self->{notebook}->GetSelection;
    if ( $self->_buffer_changed($id) ) {
        my $ret = Wx::MessageBox(
            "File changed. Do yo want to save it?",
            "Unsaved file",
            wxYES_NO|wxCANCEL|wxCENTRE,
            $self,
        );
        if ( $ret == wxYES ) {
            $self->on_save();
        } elsif ( $ret == wxNO ) {
            # just close it
        } else {
            # wxCANCEL, or when clicking on [x]
            return;
        }
    }
    $self->{notebook}->DeletePage($id); 

    $self->_remove_alt_n_menu();
    foreach my $i (0..@{ $self->{menu}->{alt} } -1) {
        $self->_update_alt_n_menu(scalar($self->_get_filename($i)), $i);
    }

    return;
}

sub _buffer_changed {
    my ($self, $id) = @_;
    my $page = $self->{notebook}->GetPage($id);
    return $page->GetModify;
}

sub on_setup {
    my ($self) = @_;
    my $config = Padre->ide->get_config;

    my $dialog = Wx::Dialog->new( $self, -1, "Configuration", [-1, -1], [550, 200]);

    Wx::StaticText->new( $dialog, -1, 'Max number of modules', [10, 10], [-1, -1]);
    my $max = Wx::TextCtrl->new( $dialog, -1, $config->{DISPLAY_MAX_LIMIT}, [300, 10] , [-1, -1]);

    Wx::StaticText->new( $dialog, -1, 'Min number of modules', [10, 40], [-1, -1]);
    my $min = Wx::TextCtrl->new( $dialog, -1, $config->{DISPLAY_MIN_LIMIT}, [300, 40] , [-1, -1]);

    Wx::StaticText->new( $dialog, -1, 'Open files:', [10, 70], [-1, -1]);
    my @values = ($config->{startup}, grep {$_ ne $config->{startup}} qw(new nothing last));

    my $choice = Wx::Choice->new( $dialog, -1, [300, 70], [-1, -1], \@values);

    EVT_BUTTON( $dialog, Wx::Button->new( $dialog, wxID_OK,     '', [10, 110] ),
                sub { $dialog->EndModal(wxID_OK) } );
    EVT_BUTTON( $dialog, Wx::Button->new( $dialog, wxID_CANCEL, '', [120, 110] ),
                sub { $dialog->EndModal(wxID_CANCEL) } );

    if ($dialog->ShowModal == wxID_CANCEL) {
        return;
    }
    $config->{DISPLAY_MAX_LIMIT} = $max->GetValue;
    $config->{DISPLAY_MIN_LIMIT} = $min->GetValue;

    $config->{startup} =  $values[ $choice->GetSelection];
    #Padre->ide->set_config($config);

    return;
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

sub on_find {
    my ( $self ) = @_;

    my $config = Padre->ide->get_config;
    my $selection = $self->_get_selection();
    $selection = '' if not defined $selection;

    my $search = Padre::Wx::FindDialog->new( $self, $config, {term => $selection} );
    return if not $search;

    if ($search->{term}) {
        unshift @{$config->{search_terms}}, $search->{term};
        my %seen;
        @{$config->{search_terms}} = grep {!$seen{$_}++} @{$config->{search_terms}};
    }
    if ($search->{replace_term} ) {
        unshift @{$config->{replace_terms}}, $search->{replace_term};
        my %seen;
        @{$config->{replace_terms}} = grep {!$seen{$_}++} @{$config->{replace_terms}};
     }

    $self->_search(replace_term => $search->{replace_term});

    return;
}

sub update_methods {
    my ($self) = @_;

    my $text = $self->get_current_content;
    my @methods = reverse sort $text =~ m{sub\s+(\w+)}g;
    $self->{rightbar}->DeleteAllItems;
    $self->{rightbar}->InsertStringItem(0, $_) for @methods;
    $self->{rightbar}->SetColumnWidth(0, wxLIST_AUTOSIZE);


    return;
}

sub _search {
    my ($self, %args) = @_;

    my $config = Padre->ide->get_config;
    my $search_term = $args{search_term} ||= $config->{search_terms}->[0];
    #$args{replace_term}

    my $id   = $self->{notebook}->GetSelection;
    my $page = $self->{notebook}->GetPage($id);
    my $content = $page->GetText;
    my ($from, $to) = $page->GetSelection;
    if ($from < $to) {
        $from++;
    }
    my $last = $page->GetLength();
    my $str  = $page->GetTextRange($from, $last);

    if ($config->{case_insensitive}) {
        $search_term = "(?i)$search_term";
    }
    #print $search_term, "\n";
    my $regex = qr/$search_term/;

    # @LAST_MATCH_START
    # @LAST_MATCH_END
    my $pos;
    if ($str =~ $regex) {
        $pos = $LAST_MATCH_START[0] + $from;
    } else {
        my $str  = $page->GetTextRange(0, $last);
        if ($str =~ $regex) {
            $pos = $LAST_MATCH_START[0];
        }
    }
    if (not defined $pos) {
        return; # not found
    }

    $page->SetSelection($pos, $pos+length($search_term));

    return;
}

sub on_find_again {
    my $self = shift;
    my $term = Padre->ide->get_config->{search_terms}->[0];
    if ( $term ) {
        $self->_search;
    } else {
        $self->on_find;
    }
    return;
}

sub on_about {
    my ( $self ) = @_;

    Wx::MessageBox( 
        "Perl Application Development and Refactoring Environment\n" .
        "Padre $Padre::VERSION, (c) 2008 Gabor Szabo\n" .
        "Using Wx v$Wx::VERSION, binding " . wxVERSION_STRING,
        "About Padre", wxOK|wxCENTRE, $self );
}

sub on_help {
    my ( $self ) = @_;

    if ( not $self->{help} ) {
        $self->{help} = Padre::Pod::Frame->new;
        my $module = Padre->ide->get_current('pod') || 'Padre';
        if ($module) {
            $self->{help}->{html}->display($module);
        }
    }
    $self->{help}->SetFocus;
    $self->{help}->Show (1);

    return;
}
sub on_context_help {
    my ($self) = @_;

    my $selection = $self->_get_selection();

    $self->on_help;

    if ($selection) {
        $self->{help}->show($selection);
    }

    return;
}

sub _get_selection {
    my ($self, $id) = @_;

    if (not defined $id) {
        $id  = $self->{notebook}->GetSelection;
    }
    return if $id == -1;
    my $page = $self->{notebook}->GetPage($id);
    return $page->GetSelectedText;
}

sub on_run_this {
    my ($self) = @_;

    my $config = Padre->ide->get_config;
    if ($config->{save_on_run} eq 'same') {
        $self->on_save;
    } elsif ($config->{save_on_run} eq 'all_files') {
    } elsif ($config->{save_on_run} eq 'all_buffer') {
    }

    my $id   = $self->{notebook}->GetSelection;
    my $filename = $self->_get_filename($id);
    if (not $filename) {
        Wx::MessageBox( "No filename, cannot run", "Cannot run", wxOK|wxCENTRE, $self );
        return;
    }
    if (substr($filename, -3) ne '.pl') {
        Wx::MessageBox( "Currently we only support execution of .pl files", "Cannot run", wxOK|wxCENTRE, $self );
        return;
    }

    # Run the program
    my $perl = Padre->probe_perl->find_perl_interpreter;
    $self->_run( qq["perl" "$filename"] );

    return;
}

sub on_debug_this {
    my ($self) = @_;
    $self->on_save;

    my $id   = $self->{notebook}->GetSelection;
    my $filename = $self->_get_filename($id);


    my $host = 'localhost';
    my $port = 12345;

    _setup_debugger($host, $port);

    local $ENV{PERLDB_OPTS} = "RemotePort=$host:$port";
    my $perl = Padre->probe_perl->find_perl_interpreter;
    $self->_run(qq["$perl" -d "$filename"]);

    return;
}

# based on remoteport from "Pro Perl Debugging by Richard Foley and Andy Lester"
sub _setup_debugger {
    my ($host, $port) = @_;

#use IO::Socket;
#use Term::ReadLine;
#
#    my $term = new Term::ReadLine 'local prompter';
#
#    # Open the socket the debugger will connect to.
#    my $sock = IO::Socket::INET->new(
#                   LocalHost => $host,
#                   LocalPort => $port,
#                   Proto     => 'tcp',
#                   Listen    => SOMAXCONN,
#                   Reuse     => 1);
#    $sock or die "no socket :$!";
#
#    my $new_sock = $sock->accept();
#    my $remote_host = gethostbyaddr($sock->sockaddr(), AF_INET) || 'remote';
#    my $prompt = "($remote_host)> ";
}

sub _run {
    my ($self, $cmd) = @_;

    $self->{menu}->{run_this}->Enable(0);
    $self->{menu}->{run_any}->Enable(0);
    $self->{menu}->{run_stop}->Enable(1);

    my $config = Padre->ide->get_config;
    $self->{main_panel}->SetSashPosition($config->{main}->{height} - 300);
    $self->{output}->Remove( 0, $self->{output}->GetLastPosition );

    $self->{proc} = Wx::Perl::ProcessStream->OpenProcess($cmd, 'MyName1', $self);
    if ( not $self->{proc} ) {
       $self->{menu}->{run_this}->Enable(1);
       $self->{menu}->{run_any}->Enable(1);
       $self->{menu}->{run_stop}->Enable(0);
    }
    return;
}

sub on_run {
    my ($self) = @_;

    my $config = Padre->ide->get_config;
    if (not $config->{command_line}) {
        $self->on_setup_run;
    }
    return if not $config->{command_line};
    $self->_run($config->{command_line});

    return;
}


sub on_setup_run {
    my ($self) = @_;

    my $config = Padre->ide->get_config;
    my $dialog = Wx::TextEntryDialog->new( $self, "Command line", "Run setup", $config->{command_line} );
    if ($dialog->ShowModal == wxID_CANCEL) {
        return;
    }
#    my @values = ($config->{startup}, grep {$_ ne $config->{startup}} qw(new nothing last));

#    my $choice = Wx::Choice->new( $dialog, -1, [300, 70], [-1, -1], \@values);

    $config->{command_line} = $dialog->GetValue;
    $dialog->Destroy;

    return;
}

sub on_toggle_show_output {
    my ($self, $event) = @_;

    # Update the output panel
    my $config = Padre->ide->get_config;
    $self->{main_panel}->SetSashPosition(
        $config->{main}->{height} - ($event->IsChecked ? 100 : 0)
    );

    return;
}

sub on_toggle_status_bar {
    my ($self, $event) = @_;

    # Update the configuration
    my $config = Padre->ide->get_config;
    $config->{show_status_bar} = $event->IsChecked ? 1 : 0;

    # Update the status bar
    my $status_bar = $self->GetStatusBar;
    if ( $config->{show_status_bar} ) {
        $status_bar->Hide;
    } else {
        $status_bar->Show;
    }

    return;
}

sub evt_process_stdout {
    my ($self, $event) = @_;
    $event->Skip(1);
    $self->{output}->AppendText( $event->GetLine . "\n");
    return;
}

sub evt_process_stderr {
    my ($self, $event) = @_;
    $event->Skip(1);
    $self->{output}->AppendText( $event->GetLine . "\n");
    return;
}

sub evt_process_exit {
    my ($self, $event) = @_;

    $event->Skip(1);
    my $process = $event->GetProcess;
    #my $line = $event->GetLine;
    #my @buffers = @{ $process->GetStdOutBuffer };
    #my @errors = @{ $process->GetStdOutBuffer };
    #my $exitcode = $process->GetExitCode;
    $process->Destroy;

    $self->{menu}->{run_this}->Enable(1);
    $self->{menu}->{run_any}->Enable(1);
    $self->{menu}->{run_stop}->Enable(0);

    return;
}

sub on_stop {
    my ($self) = @_;
    $self->{proc}->TerminateProcess if $self->{proc};
    return;
}

sub on_undo { # Ctrl-Z
    my ($self) = @_;

    my $id = $self->{notebook}->GetSelection;
    my $page = $self->{notebook}->GetPage($id);
    if ($page->CanUndo) {
       $page->Undo;
    }

    return;
}

sub on_redo { # Shift-Ctr-Z
    my ($self) = @_;

    my $id = $self->{notebook}->GetSelection;
    my $page = $self->{notebook}->GetPage($id);
    if ($page->CanRedo) {
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

    my $box  = Wx::BoxSizer->new(  wxVERTICAL );
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

    return if $self->{_in_setup_editor};

    my $pageid = $self->{notebook}->GetSelection();
    if (not defined $pageid) {
        $self->SetStatusText("", $_) for (0..2);
        return;
    }
    my $page = $self->{notebook}->GetPage($pageid);
    my $line = $page->GetCurrentLine;
    my ($filename, $file_type) = $self->_get_filename($pageid);
    $filename  ||= '';
    $file_type ||= _get_local_filetype();
    my $modified = $page->GetModify ? '*' : ' ';

    if ($filename) {
        $self->{notebook}->SetPageText($pageid, $modified . File::Basename::basename $filename);
    } else {
        my $text = substr($self->{notebook}->GetPageText($pageid), 1);
        $self->{notebook}->SetPageText($pageid, $modified . $text);
    }
    my $pos = $page->GetCurrentPos;

    my $start = $page->PositionFromLine($line);
    my $char = $pos-$start;

    $self->SetStatusText("$modified $filename", 0);
    $self->SetStatusText($file_type, 1);

    $self->SetStatusText("L: " . ($line +1) . " Ch: $char", 2);

    return;
}

sub on_panel_changed {
    my ($self) = @_;

    $self->update_status;
    $self->update_methods;

    return;
}

1;
