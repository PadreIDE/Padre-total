package Padre::Frame;
use strict;
use warnings;

my $output;
my $run_this_menu;
my $debug_this_menu;
my $run_menu;
my $stop_menu;
my $proc;
my $help;

sub say { print @_, "\n" }

my %marker;

use Wx        qw(:everything);
use Wx::Event qw(:everything);
use Wx::Perl::ProcessStream qw( :everything );

use base 'Wx::Frame';

use Padre::Pod::Frame;
use Padre::Panel;

use FindBin;
use File::Spec::Functions qw(catfile catdir);
use File::Slurp     qw(read_file write_file);
use File::Basename  qw(basename fileparse);
use Carp            qw();
use Data::Dumper    qw(Dumper);
use List::Util      qw(max);
use File::ShareDir  ();
my $default_dir = "";
our $nb;
my $cnt = 0;

our $VERSION = '0.01';

# see Wx-0.84/ext/stc/cpp/st_constants.cpp for extension
my %syntax_of = (
    css  => wxSTC_LEX_CSS,
    html => wxSTC_LEX_HTML,
#    js   => 
    pl   => wxSTC_LEX_PERL,
    pod  => wxSTC_LEX_PERL,
    pm   => wxSTC_LEX_PERL,
    sql  => wxSTC_LEX_SQL,
    t    => wxSTC_LEX_PERL,
    xml  => wxSTC_LEX_XML,
    yml  => wxSTC_LEX_YAML,
    yaml => wxSTC_LEX_YAML,
    _default_ => wxSTC_LEX_AUTOMATIC,
);


sub new {
    my ($class) = @_;

    my $config = $main::app->get_config;
    my $self = $class->SUPER::new( undef, -1,
                                 'Padre ',
                                  wxDefaultPosition,  
                                 [$config->{main}{width}, $config->{main}{height}],
                                  #wxDEFAULT_FRAME_STYLE|wxNO_FULL_REPAINT_ON_RESIZE|wxCLIP_CHILDREN 
                                 );
    $self->_create_menu_bar;
    $self->_create_panel;
    $self->_load_files;

    EVT_WXP_PROCESS_STREAM_STDOUT( $self, \&evt_process_stdout);
    EVT_WXP_PROCESS_STREAM_STDERR( $self, \&evt_process_stderr);
    EVT_WXP_PROCESS_STREAM_EXIT( $self,   \&evt_process_exit);

    return $self;
}

sub _create_panel {
    my ($self) = @_;

    my $main_panel = Wx::SplitterWindow->new(
                $self, -1, wxDefaultPosition, wxDefaultSize,
                wxNO_FULL_REPAINT_ON_RESIZE|wxCLIP_CHILDREN );
    $main::app->set_widget('main_panel', $main_panel);

    $nb = Wx::Notebook->new
      ( $main_panel, -1, wxDefaultPosition, wxDefaultSize,
        wxNO_FULL_REPAINT_ON_RESIZE|wxCLIP_CHILDREN );

    $output = Wx::TextCtrl->new( $main_panel, -1, "", 
        wxDefaultPosition, wxDefaultSize,
        wxTE_READONLY|wxTE_MULTILINE|wxNO_FULL_REPAINT_ON_RESIZE );

    my $config = $main::app->get_config;    
    $main_panel->SplitHorizontally( $nb, $output, $config->{main}{height} );

    $self->CreateStatusBar;
    my $tool_bar = $self->CreateToolBar( wxTB_HORIZONTAL | wxNO_BORDER | wxTB_FLAT | wxTB_DOCKABLE, 5050);
    $tool_bar->AddTool(wxID_NEW, '', _bitmap('new'), 'New File');
    $tool_bar->AddTool(wxID_OPEN, '', _bitmap('open'), 'Open');
    $tool_bar->AddTool(wxID_SAVE, '', _bitmap('save'), 'Save');

    EVT_NOTEBOOK_PAGE_CHANGED($self, $nb, \&on_panel_changed);

    return;
}

sub _bitmap($) {
    my $file = shift;

    my $dir = $ENV{PADRE_DEV} ? catdir($FindBin::Bin, '..', 'share') : File::ShareDir::dist_dir('Padre');
    my $path = catfile($dir , 'docview', "$file.xpm" );
    return Wx::Bitmap->new( $path, wxBITMAP_TYPE_XPM );
}


sub _load_files {
    my ($self) = @_;

    my $config = $main::app->get_config;

    # TODO make sure the full path to the file is saved and not
    # the relative path
    my @files = $main::app->get_files;
    if (@files) {
        foreach my $f (@files) {
            $self->setup_editor($f);
        }
    } elsif ($config->{startup} eq 'new') {
        $self->setup_editor;
    } elsif ($config->{startup} eq 'nothing') {
        # nothing
    } elsif ($config->{startup} eq 'last') {
        if ($config->{main}{files} and ref $config->{main}{files} eq 'ARRAY') {
            my @files = @{ $config->{main}{files} };
            foreach my $f (@files) {
                $self->setup_editor($f);
            }
        }
    } else {
        # should never happen
    }
    return;
}

sub _create_menu_bar {
    my ($self) = @_;

    my %plugins = %{ $main::app->{plugins} };

    my $bar     = Wx::MenuBar->new;

    my $file    = Wx::Menu->new;
    my $project = Wx::Menu->new;
    my $view    = Wx::Menu->new;
    my $run     = Wx::Menu->new;
    my $edit    = Wx::Menu->new;
    my $plugin_menu = Wx::Menu->new;
    my $help    = Wx::Menu->new;
    $bar->Append( $file,    "&File" );
    $bar->Append( $project, "&Project" );
    $bar->Append( $edit,    "&Edit" );
    $bar->Append( $view,    "&View" );
    $bar->Append( $run,     "&Run" );
    if (%plugins) {
        $bar->Append( $plugin_menu,     "Pl&ugins" );
    }
    $bar->Append( $help,    "&Help" );

    $self->SetMenuBar( $bar );

    my $config = $main::app->get_config;

    EVT_MENU(  $self, $file->Append( wxID_NEW,    ''  ), \&on_new     );
    EVT_MENU(  $self, $file->Append( wxID_OPEN,   ''  ), \&on_open    );
    my $recent = Wx::Menu->new;
    foreach my $f ($main::app->get_recent('files')) {
       EVT_MENU ($self, $recent->Append(-1, $f), sub { $_[0]->setup_editor($f) } );
    }

    #$file->AppendSubMenu( $recent, "Recent Files" );
    # to support older version of wxWidgets as well
    $file->Append( -1, "Recent Files", $recent );

    EVT_MENU(  $self, $file->Append( wxID_SAVE,   ''  ), \&on_save    );
    EVT_MENU(  $self, $file->Append( wxID_SAVEAS, ''  ), \&on_save_as );
    EVT_MENU(  $self, $file->Append( -1, 'Save All'  ), \&on_save_all );
    EVT_MENU(  $self, $file->Append( wxID_CLOSE,  ''  ), \&on_close   );
    EVT_MENU(  $self, $file->Append( wxID_EXIT,   ''  ), \&on_exit    );

#    EVT_MENU(  $self, $project->Append( -1, "&Create New"), \&on_create_project );
    EVT_MENU(  $self, $project->Append( -1, "&Select"    ), \&on_select_project );
#    EVT_MENU(  $self, $project->Append( -1, "&Test"      ), \&on_test_project );

    EVT_MENU( $self, $edit->Append( wxID_UNDO,    ''       ), \&on_undo    );
    EVT_MENU( $self, $edit->Append( wxID_REDO,    ''       ), \&on_redo    );
#    EVT_MENU( $self, $edit->Append( wxID_COPY,    ''       ), \&on_copy    );
#    EVT_MENU( $self, $edit->Append( wxID_PASTE,   ''       ), \&on_paste   );
    EVT_MENU( $self, $edit->Append( wxID_FIND,    ''       ), \&on_find    );
    EVT_MENU( $self, $edit->Append( -1,           "&Find Again\tF3"  ), \&on_find_again    );
    EVT_MENU( $self, $edit->Append( -1,           "&Goto\tCtrl-G"     ), \&on_goto    );
    EVT_MENU( $self, $edit->Append( -1,           "&Setup"      ), \&on_setup   );

    my $chk = $view->AppendCheckItem( -1 , "Line numbers" );
    if ($config->{show_line_numbers}) {
       $chk->Check(1);
    }
    EVT_MENU( $self, $chk, \&on_toggle_line_numbers);
    EVT_MENU( $self, $view->AppendCheckItem( -1 , "Show Output" ), \&on_toggle_show_output);
    EVT_MENU( $self, $view->AppendCheckItem( -1 , "Hide StatusBar" ), \&on_toggle_status_bar);

    ## Help
    $run_this_menu  = $run->Append( -1 , "Run &This\tF5" );
    #$debug_this_menu  = $run->Append( -1 , "Debug This\tF6" );
    $run_menu  = $run->Append( -1 , "&Run Any\tCtrl-F5" );
    $stop_menu = $run->Append( -1 , "&Stop" );
    EVT_MENU( $self, $run_this_menu,  \&on_run_this);
    #EVT_MENU( $self, $debug_this_menu,  \&on_debug_this);
    EVT_MENU( $self, $run_menu,  \&on_run);
    EVT_MENU( $self, $stop_menu,  \&on_stop);
    $stop_menu->Enable(0);

    EVT_MENU( $self, $run->Append( -1,           "&Setup"      ), \&on_setup_run   );

    ## Plugins
    foreach my $name (sort keys %plugins) {
        next if not $plugins{$name};
        my $submenu = Wx::Menu->new;
        my @menu = eval {$plugins{$name}->menu;};
        warn "Error when calling menu for plugin '$name' $@" if $@;
        foreach my $m (@menu) {
           EVT_MENU ($self, $submenu->Append(-1, $m->[0]), $m->[1] );
        }
        #$plugin_menu->AppendSubMenu( $submenu, $name );
        $plugin_menu->Append(-1,$name, $submenu);
    }


    ## Help
    EVT_MENU( $self, $help->Append( wxID_ABOUT,   '' ), \&on_about   );
    EVT_MENU( $self, $help->Append( wxID_HELP,    '' ), \&on_help    );
    EVT_MENU( $self, $help->Append( -1,    'Context-help  Ctrl-Shift-H' ), \&on_context_help    );

    EVT_CLOSE( $self,              \&on_close_window);

    EVT_KEY_UP( $self, \&on_key );
    return;
}

sub on_key {
    my ($self, $event) = @_;

    $self->update_status;

    my $mod  = $event->GetModifiers() || 0;
    my $code = $event->GetKeyCode;
    #print "$mod $code\n";
    if (not $mod) {
        if ($code == WXK_F7) {             # F7
            print "experimental - sending s to debugger\n";
        }
    } elsif ($mod == 1) {                        # Alt
        if (57 >= $code and $code >= 49) {       # Alt-1-9
            my $id = $code - 49;
            $self->on_nth_pane($id);
        }
    } elsif ($mod == 10) {            # Ctrl
        if (57 >= $code and $code >= 49) {       # Ctrl-1-9
            my $id = $code - 49;
            my $pageid = $nb->GetSelection();
            my $page = $nb->GetPage($pageid);
            my $line = $page->GetCurrentLine;
            $marker{$id} = $line;
#print "set marker $id to line $line\n";
            #$page->MarkerAdd($line, $id);
        } elsif ($code == WXK_TAB) {              # Ctrl-TAB
            $self->on_next_pane;
        } elsif ($code == ord 'P') {              # Ctrl-P    Auto completition
            my $id   = $nb->GetSelection;
            my $page = $nb->GetPage($id);
            my $pos  = $page->GetCurrentPos;
            my $line = $page->LineFromPosition($pos);
            my $first = $page->PositionFromLine($line);
            my $prefix = $page->GetTextRange($first, $pos); # line from beginning to current position
            $prefix =~ s{^.*?(\w+)$}{$1};
            print "prefix: '$prefix'\n";
            my $last = $page->GetLength();
            my $text = $page->GetTextRange(0, $last);
            my %seen;
            my @words = grep { !$seen{$_}++ } sort ($text =~ m{\b($prefix\w*)\b}g);
            if (@words > 20) {
               @words = @words[0..19];
            }
            $page->AutoCompShow(3, join " ", @words);
            return;
        } elsif ($code == ord 'B') {              # Ctrl-B    Brace matching?
            my $id   = $nb->GetSelection;
            my $page = $nb->GetPage($id);
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
        } elsif ($code == ord 'M') {              # Ctrl-M    comment out block of code
            my $pageid = $nb->GetSelection();
            my $page = $nb->GetPage($pageid);
            my $start = $page->LineFromPosition($page->GetSelectionStart);
            my $end = $page->LineFromPosition($page->GetSelectionEnd);
            for my $line ($start .. $end) {
                # TODO: this should actually depend on language
                # insert #
                my $pos = $page->PositionFromLine($line);
                $page->InsertText($pos, '#');
            }
        }
    } elsif ($mod == 6) {                         # Ctrl-Shift
        if ($code == ord 'H') {                   # Ctrl-Shift-H
            $self->on_context_help;
        } elsif ($code == WXK_TAB) {              # Ctrl-Shift-TAB
            $self->on_prev_pane;
        } elsif ($code == ord 'Z') {              # Ctrl-Shift-Z
            $self->on_redo;
        } elsif (57 >= $code and $code >= 49) {   # Ctrl-Shift-1-9      go to marker $id\n";
            my $id = $code - 49;
            my $pageid = $nb->GetSelection();
            my $page = $nb->GetPage($pageid);
            if (defined $marker{$id}) {
                $page->GotoLine($marker{$id});
            }
        } elsif ($code == ord 'M') {             # Ctrl-Shift-M    uncomment block of code
            my $pageid = $nb->GetSelection();
            my $page = $nb->GetPage($pageid);
            my $start = $page->LineFromPosition($page->GetSelectionStart);
            my $end = $page->LineFromPosition($page->GetSelectionEnd);
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
        }
    }


    return;
}

sub on_exit {
    my ($self) = @_;
    $self->Close
}

	
sub on_close_window {
    my ( $self, $event ) = @_;

    my $config = $main::app->get_config;

    if ($event->CanVeto) {
        my @unsaved;
        foreach my $id (0 .. $nb->GetPageCount -1) {
            if (_buffer_changed($id)) {
                push @unsaved, $nb->GetPageText($id);
            }
        }
        if (@unsaved) {
            Wx::MessageBox( "The following buffers are still not saved:\n" . join("\n", @unsaved), 
                            "Unsaved", wxOK|wxCENTRE, $self );
            $event->Veto;
            return;
        }

        my @files = map { $self->_get_filename($_) } (0 .. $nb->GetPageCount -1);
        $config->{main}{files} = \@files;
    }

    ($config->{main}{width}, $config->{main}{height}) = $self->GetSizeWH;
    #$main::app->set_config($config);
    $main::app->save_config();

    $help->Destroy if $help;

    $event->Skip;
}

sub _lexer {
    my ($file) = @_;

    return $syntax_of{_default_} if not $file;
    (my $ext = $file) =~ s{.*\.}{};
    $ext = lc $ext;
    return $syntax_of{_default_} if not $ext;
    return( (defined $syntax_of{$ext}) ? $syntax_of{$ext} : $syntax_of{_default_});
}

sub setup_editor {
    my ($self, $file) = @_;

    $self->{_in_setup_editor} = 1;

    my $config = $main::app->get_config;


    my $editor = Padre::Panel->new($nb, _lexer($file));

    #$editor->SetEOLMode( Wx::wxSTC_EOL_CRLF );
    # it used to default to 0 on windows and still
    # it was adding extra characters
    #print $editor->GetEOLMode, "\n"; #0
#    print Wx::wxSTC_EOL_CR, "\n";1
#    print Wx::wxSTC_EOL_CRLF, "\n"0;
#    print Wx::wxSTC_EOL_LF, "\n";2

    $cnt++;
    my $title = " Unsaved Document $cnt";
    my $content = '';
    if ($file) {
        $content = read_file($file);
        $title   = basename($file);
        $editor->SetText( $content );
        $editor->EmptyUndoBuffer;
    }
    _toggle_numbers($editor, $config->{show_line_numbers});

    $nb->AddPage($editor, $title, 1); # TODO add closing x
    $editor->SetFocus;
    my $pack = __PACKAGE__;
    #my $page = $nb->GetCurrentPage;
    my $id  = $nb->GetSelection;
    _set_filename($id, $file);
    #print "x" . $editor->AutoCompActive .  "x\n";

    delete $self->{_in_setup_editor};
    $self->update_status;
    return;
}

sub on_toggle_line_numbers {
    my ($self, $event) = @_;

    my $config = $main::app->get_config;
    $config->{show_line_numbers} = $event->IsChecked ? 1 : 0;

    foreach my $id (0 .. $nb->GetPageCount -1) {
        my $editor = $nb->GetPage($id);
        #my $editor = $nb->GetPage($id);

        #$editor->SetMarginLeft(200); # this is not the area of the number but on its right
        #$editor->SetMarginMask(0, wxSTC_STYLE_LINENUMBER);
        
        _toggle_numbers($editor, $config->{show_line_numbers})
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
        my $n = 1 + max (2, length ($editor->GetLineCount * 2));
        my $width = $n * $editor->TextWidth(wxSTC_STYLE_LINENUMBER, "9"); # width of a single character
        $editor->SetMarginWidth(0, $width);
        $editor->SetMarginType(0, wxSTC_MARGIN_NUMBER);
    } else {
        $editor->SetMarginWidth(0, 0);
        $editor->SetMarginType(0, wxSTC_MARGIN_NUMBER);
    }
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

    my $file = catfile($default_dir, $filename);
    $main::app->add_to_recent('files', $file);


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
    my ($id, $data) = @_;

    my $pack = __PACKAGE__;
    my $page = $nb->GetPage($id);
    $page->{$pack}{filename} = $data;

    if ($data) {
       $page->SetLexer( _lexer($data) ); # set the syntax highlighting
       $page->Colourise(0, $page->GetTextLength);
    }

    return;
}
sub _get_filename {
    my ($self, $id) = @_;

    my $pack = __PACKAGE__;
    my $page = $nb->GetPage($id);

    return $page->{$pack}{filename};
}


sub on_save_as {
    my ($self) = @_;

    my $id   = $nb->GetSelection;
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

        my $path = catfile($default_dir, $filename);
        if (-e $path) {
            my $res = Wx::MessageBox("File already exists. Overwrite it?", "Exist", wxYES_NO, $self);
            if ($res == wxYES) {
                _set_filename($id, $path);
                last;
            }
        } else {
            _set_filename($id, $path);
            last;
        }
    }
    $self->_save_buffer($id);
    return;
}

sub on_save {
    my ($self) = @_;

    my $id   = $nb->GetSelection;
    return if $id == -1;

    return if not _buffer_changed($id) and $self->_get_filename($id);

    if ($self->_get_filename($id)) {
        $self->_save_buffer($id);
    } else {
        $self->on_save_as();
    }
    return;
}

sub on_save_all {
    my ($self) = @_;
    foreach my $id (0 .. $nb->GetPageCount -1) {
        if (_buffer_changed($id)) {
            $self->_save_buffer($id);
        }
    }
    return;
}

sub _save_buffer {
    my ($self, $id) = @_;

    my $page = $nb->GetPage($id);
    my $content = $page->GetText;
    my $filename = $self->_get_filename($id);
    eval {
        write_file($filename, $content);
    };
    $main::app->add_to_recent('files', $filename);
    $nb->SetPageText($id, basename($filename));
    $page->SetSavePoint;
    $self->update_status;

    return; 
}

sub on_close {
    my ($self) = @_;
    
    my $id   = $nb->GetSelection;
    #print "Closing $id\n";
    if (_buffer_changed($id)) {
        my $ret = Wx::MessageBox( "Buffer changed. Do yo want to save it?", "Unsaved buffer", wxYES_NO|wxCANCEL|wxCENTRE, $self );
        if ($ret == wxYES) {
            $self->on_save();
        } elsif ($ret == wxNO) {
            # just close it
        } else {
            # wxCANCEL, or when clicking on [x]
            return;
        }
    }
    $nb->DeletePage($id); 
    return;
}
sub _buffer_changed {
    my ($id) = @_;

    my $page = $nb->GetPage($id);
    return $page->GetModify;
}

sub on_setup {
    my ($self) = @_;

    my $config = $main::app->get_config;

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
    #$main::app->set_config($config);

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

    my $id   = $nb->GetSelection;
    my $page = $nb->GetPage($id);

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

    my $config = $main::app->get_config;

    my $dialog = Wx::Dialog->new( $self, -1, "Search", [-1, -1], [-1, -1]);

    my $box  = Wx::BoxSizer->new(  wxVERTICAL );
    my $row1 = Wx::BoxSizer->new(  wxHORIZONTAL );
    my $row2 = Wx::BoxSizer->new(  wxHORIZONTAL );
    my $row3 = Wx::BoxSizer->new(  wxHORIZONTAL );
    my $row4 = Wx::BoxSizer->new(  wxHORIZONTAL );

    $box->Add($row1);
    $box->Add($row2);
    $box->Add($row3);
    $box->Add($row4);

    #my @projects = keys %{ $config->{projects} };
    #push @$search_terms, $search_term if defined $search_term and $search_term ne '';

    my $selection = $self->_get_selection();
    $selection = '' if not defined $selection;
    my $choice = Wx::ComboBox->new( $dialog, -1, $selection, [-1, -1], [-1, -1], $config->{search_terms});
    $row1->Add( $choice, 1, wxALL, 3);

    #my $verbatim = Wx::CheckBox->new( $dialog, -1, "Verbatim", [-1, -1], [-1, -1]);
    #$row2->Add($verbatim);

    #my $case_insensitive = Wx::CheckBox->new( $dialog, -1, "Case Insensitive", [-1, -1], [-1, -1]);
    #$row2->Add($case_insensitive);


#    $row2->Add($dir_selector, 1, wxALL, 3);

#    my $path = Wx::StaticText->new( $dialog, -1, '');
#    $row3->Add( $path, 1, wxALL, 3 );
#    EVT_BUTTON( $dialog, $dir_selector, sub {on_pick_project_dir($path, @_) } );
    #wxTE_PROCESS_ENTER
    EVT_TEXT_ENTER($dialog, $choice, sub { $dialog->EndModal(wxID_OK) });

    my $ok     = Wx::Button->new( $dialog, wxID_OK,     '');
    my $cancel = Wx::Button->new( $dialog, wxID_CANCEL, '');
    EVT_BUTTON( $dialog, $ok,     sub { $dialog->EndModal(wxID_OK)     } );
    EVT_BUTTON( $dialog, $cancel, sub { $dialog->EndModal(wxID_CANCEL) } );
    $row4->Add($cancel, 1, wxALL, 3);
    $row4->Add($ok,     1, wxALL, 3);

    $dialog->SetSizer($box);
    #$box->SetSizeHints( $self );

    $choice->SetFocus;
    if ($dialog->ShowModal == wxID_CANCEL) {
        return;
    }
    my $search_term = $choice->GetValue;
    $dialog->Destroy;

    return if not defined $search_term or $search_term eq '';

    unshift @{$config->{search_terms}}, $search_term;
    my %seen;
    @{$config->{search_terms}} = grep {!$seen{$_}++} @{$config->{search_terms}};

    $self->_search();

    return;
}

sub _search {
    my ($self) = @_;

    my $config = $main::app->get_config;
    my $search_term = $config->{search_terms}[0];

    my $id   = $nb->GetSelection;
    my $page = $nb->GetPage($id);
    my $content = $page->GetText;
    my ($from, $to) = $page->GetSelection;
    my $last = $page->GetLength();
    my $str  = $page->GetTextRange(0, $last);
    my $pos = index($str, $search_term, $from+1);
    if (-1 == $pos) {
        $pos = index($str, $search_term);
    }
    if (-1 == $pos) {
        return; # not found
    }

    $page->SetSelection($pos, $pos+length($search_term));

    return;
}

sub on_find_again {
    my ($self) = @_;

    my $config = $main::app->get_config;
    my $search_term = $config->{search_terms}[0];

    if ($search_term) {
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

    if (not $help) {
        $help = Padre::Pod::Frame->new;
        my $module = $main::app->get_current('pod') || 'Padre';
        if ($module) {
            $help->{html}->display($module);
        }
    }
    $help->SetFocus;
    $help->Show (1);

    return;
}
sub on_context_help {
    my ($self) = @_;

    my $selection = $self->_get_selection();

    $self->on_help;

    if ($selection) {
        $help->show($selection);
    }

    return;
}

sub _get_selection {
    my ($self, $id) = @_;

    if (not defined $id) {
        $id  = $nb->GetSelection;
    }
    my $page = $nb->GetPage($id);
    return $page->GetSelectedText;
}

sub on_run_this {
    my ($self) = @_;

    my $config = $main::app->get_config;
    if ($config->{save_on_run} eq 'same') {
        $self->on_save;
    } elsif ($config->{save_on_run} eq 'all_files') {
    } elsif ($config->{save_on_run} eq 'all_buffer') {
    }

    my $id   = $nb->GetSelection;
    my $filename = $self->_get_filename($id);
    if (not $filename) {
        Wx::MessageBox( "No filename, cannot run", "Cannot run", wxOK|wxCENTRE, $self );
        return;
    }
    if (substr($filename, -3) ne '.pl') {
        Wx::MessageBox( "Currently we only support execution of .pl files", "Cannot run", wxOK|wxCENTRE, $self );
        return;
    }
    $self->_run("$^X $filename");

    return;
}

sub on_debug_this {
    my ($self) = @_;
    $self->on_save;

    my $id   = $nb->GetSelection;
    my $filename = $self->_get_filename($id);


    my $host = 'localhost';
    my $port = 12345;

    _setup_debugger($host, $port);

    local $ENV{PERLDB_OPTS} = "RemotePort=$host:$port";
    $self->_run("$^X -d $filename");

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

    $run_this_menu->Enable(0);
    $run_menu->Enable(0);
    $stop_menu->Enable(1);

    my $config = $main::app->get_config;
    $main::app->get_widget('main_panel')
        ->SetSashPosition($config->{main}{height} - 300);
    $output->Remove(0, $output->GetLastPosition);

    $proc = Wx::Perl::ProcessStream->OpenProcess($cmd, 'MyName1', $self);
    if (not $proc) {
       $run_this_menu->Enable(1);
       $run_menu->Enable(1);
       $stop_menu->Enable(0);
    }
    return;
}

sub on_run {
    my ($self) = @_;

    my $config = $main::app->get_config;
    if (not $config->{command_line}) {
        $self->on_setup_run;
    }
    return if not $config->{command_line};
    $self->_run($config->{command_line});

    return;
}


sub on_setup_run {
    my ($self) = @_;

    my $config = $main::app->get_config;
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

    my $config = $main::app->get_config;
    my $main_panel = $main::app->get_widget('main_panel');
    if ($event->IsChecked) {
        $main_panel->SetSashPosition($config->{main}{height} -100);
    } else {
        # TODO save the value and keep it for next use
        $main_panel->SetSashPosition($config->{main}{height});
    }
}

sub on_toggle_status_bar {
    my ($self, $event) = @_;

    my $status_bar = $self->GetStatusBar;
    if ($event->IsChecked) {
        $status_bar->Hide;
    } else {
        $status_bar->Show;
    }
}

sub evt_process_stdout {
    my ($self, $event) = @_;

    $event->Skip(1);
    my $process = $event->GetProcess;
    my $line = $event->GetLine;
    $output->AppendText($line . "\n");

    return;
}

sub evt_process_stderr {
    my ($self, $event) = @_;

    $event->Skip(1);
    my $process = $event->GetProcess;
    my $line = $event->GetLine;
    $output->AppendText($line . "\n");

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

    $run_this_menu->Enable(1);
    $run_menu->Enable(1);
    $stop_menu->Enable(0);

    return;
}

sub on_stop {
    my ($self) = @_;
    $proc->TerminateProcess;
    return;
}

sub on_undo { # Ctrl-Z
    my ($self) = @_;

    my $id = $nb->GetSelection;
    my $page = $nb->GetPage($id);
    if ($page->CanUndo) {
       $page->Undo;
    }

    return;
}

sub on_redo { # Shift-Ctr-Z
    my ($self) = @_;

    my $id = $nb->GetSelection;
    my $page = $nb->GetPage($id);
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

sub on_create_project {
    my ($self) = @_;
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

    my $config = $main::app->get_config;

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
    if ($config->{projects}{$project}) {
        #is changing allowed? how do we notice that it is not one of the already existing names?
    } else {
       $config->{projects}{$project}{dir} = $dir;
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
    my $page = $nb->GetPage($id);
    if ($page) {
       $nb->ChangeSelection($id);
       return 1;
    }
    return;
}
sub on_next_pane {
    my ($self) = @_;

    my $count = $nb->GetPageCount;
    return if not $count;

    my $id    = $nb->GetSelection;
    if ($id + 1 < $count) {
        $self->on_nth_pane($id + 1);
    } else {
        $self->on_nth_pane(0);
    }
    return;
}
sub on_prev_pane {
    my ($self) = @_;

    my $count = $nb->GetPageCount;
    return if not $count;

    my $id    = $nb->GetSelection;
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

    my $pageid = $nb->GetSelection();
    if (not defined $pageid) {
        $self->SetStatusText("");
        return;
    }
    my $page = $nb->GetPage($pageid);
    my $line = $page->GetCurrentLine;
    my $filename = $self->_get_filename($pageid) || '';
    my $modified = $page->GetModify ? '*' : ' ';

    if ($filename) {
        $nb->SetPageText($pageid, $modified . basename $filename);
    } else {
        my $text = substr($nb->GetPageText($pageid), 1);
        $nb->SetPageText($pageid, $modified . $text);
    }
    my $pos = $page->GetCurrentPos;

    my $start = $page->PositionFromLine($line);
    my $char = $pos-$start;

    $self->SetStatusText("$modified $filename L: " . ($line +1) . " Ch: $char");

    return;
}

sub on_panel_changed {
    my ($self) = @_;
    $self->update_status;
}

sub get_nb {
    my ($self) = @_;
    return $nb;
}

1;

