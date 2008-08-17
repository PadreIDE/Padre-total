package Padre;

=pod

=head1 NAME

Padre - Perl Application Development and Refactoring Environment

=head1 SYNOPSIS

Padre is a text editor aimed to be an IDE for Perl.

You should be able to just type in 

 padre

and get the editor working.

While I am using this editor myself there are still lots of
missing features so I would consider this application to
be in pre-alpha state.

I do so mainly becasue everything is in a constant flux.
Menus, shortcuts and the way they work will change from
version to version.

You should also know that I am mostly working on Linux and I
have been using vi for many years now. This means that I am 
not that familiar with the expectations of people using 
Windows.

=head1 DESCRIPTION

The application maintains its configuration information in a 
directory called .padre

On Strawberry Perl you can associate .pl file extension with
c:\strawberry\perl\bin\wxperl and then you can start double 
clicking on the application. It should work.

 Run This (F5) - run the current buffer with the current perl
 this currently only works with files with .pl  extensions.

 Run Any (Ctr-F5) - run any external application
 First time it will prompt you to a command line that you have to type in such as

 perl /full/path/to/my/script.pl

then it will execute this every time you press Ctrl-F5 or the menu option.
Currently Ctrl-F5 does not save any file. (This will be added later.)

You can edit the command line using the Run/Setup menu item.

 Ctr-B          matching brace
 Ctr-P          Autocompletition
 Alt-N          Nth Pane
 Ctr-TAB        Next Pane
 Ctr-Shift-TAB  Previous Pane

 Ctr-1 .. Ctrl-9 can set markers
 Ctr-Shift-1 .. Ctrl-Shift-9 jump to marker

 Ctr-M Ctr-Shift-M  comment/uncomment selected lines of code

 Ctr-H opens a help window where you can see the documentation of 
 any perl module. Just use open (in the help window) and type in the name
 of a module.

 Ctr-Shift-H Highlight the name of a module in the editor and then 
 press Ctr-Shift-H. IT will open the help window for the module 
 whose name was highlighted.

 In the help window you can also start typing the name of a module. When the
 list of the matching possible modules is small enough you'll be able
 to open the drop-down list and select the name.
 The "small enough" is controled by two configuration options in the 
 Edit/Setup menu:

 Max Number of modules
 Min Number of modules

 This feature only works after you have indexed all the modules 
 on your computer. Indexing is currently done by running the following command:

 padre --index

=head2 Rectangular Text Selection

Simple text editors usually only allow you to select contiguous lines of text with your mouse. 
Somtimes, however, it is handy to be able to select a rectangular area of text for more precise 
cutting/copying/pasting or performing search/replace on. You can select a rectangular area in Padre
by holding down Ctr-Alt whilst selecting text with your mouse. 

For example, imagine you have the following nicely formatted hash assignment in a perl source file:

 my %hash = (
    key1 => 'value1',
    key2 => 'value2',
    key3 => 'value3',
 );

With a rectangular text selection you can select only the keys, only the values, etc.. 

=head1 Command line options

 --index   will go over the @INC and list all the available modules in the database
 
 a list of filenames can be given to be opened

=head1 Plugins

There is a highly experimental but quit simple plugin system.

A plugin is a module in the Padre::Plugin::* namespace.

At startup time Padre looks for all such modules in @INC 
and loads them.
Every plugin must have a C<menu> method that returns its menu items
which is a list of lists:

 ( 
   [ Name_1, \&callback_1 ],
   [ Name_2, \&callback_2 ],
 )

Padre will add a menu entry for every plugin under the B<Plugins>
menu item. For each plugin menu item it will add all the Name_1,
Name_2 subitems.

=cut

use 5.008;
use strict;
use warnings;

our $VERSION = '0.04';

use File::Spec    ();
use File::HomeDir ();
use DBI           ();
use Carp          ();
use YAML::Tiny    ();
use Getopt::Long  ();
use Data::Dumper  qw(Dumper);
use Padre::App;

# Globally shared Perl detection object
my $probe_perl = undef;
sub probe_perl {
	unless ( $probe_perl ) {
		require Probe::Perl;
		$probe_perl = Probe::Perl->new;
	}
	return $probe_perl;
}

use base 'Class::Accessor';

__PACKAGE__->follow_best_practice;
__PACKAGE__->mk_accessors(qw(config index));

my @history = qw(files pod);

sub new {
    my ($class) = @_;
    my $self = bless {}, $class;
    $self->{recent}{$_} = [] for @history;
    $self->_process_command_line;
    $self->_locate_plugins;
    return $self;
}

sub run {
    my ($self) = @_;
    if ($self->get_index) {
        $self->run_indexer;
    } else {
        $self->run_editor;
    }
    return;
}

sub run_indexer {
    my ($self) = @_;

    require Padre::Pod::Indexer;
    my $x = Padre::Pod::Indexer->new;
    my @files = $x->list_all_files(@INC);

    $self->remove_modules();
    $self->add_modules(@files);

    #require Pod::Index;

    return;
}

sub _process_command_line {
    my ($self) = @_;

    my %opt;
    Getopt::Long::GetOptions(\%opt, "index", "help") or usage();
    usage() if $opt{help};

    $self->set_files(@ARGV);
    $self->set_index($opt{index});

    return;
}

sub _locate_plugins {
    my ($self) = @_;
    my %plugins;
    foreach my $path (@INC) {
        my $dir = File::Spec->catdir($path, 'Padre', 'Plugin');
        opendir my $dh, $dir or next;
        while (my $file = readdir $dh) {
            if ($file =~ /^\w+\.pm$/) {
                $file =~ s/\.pm$//;
                $plugins{$file} = 0;
                my $module = "Padre::Plugin::$file";
		eval "use $module"; ## no critic
                if ($@) {
                    warn "ERROR while trying to load plugin '$file': $@";
                    next;
                }
                
                $plugins{$file} = $module;
            }
        }
    }
    $self->{plugins} = \%plugins;
    return;
}

sub usage {
    die <<"END_USAGE";
Usage: $0 [FILENAMEs]
           --index to index the modules found on this computer
           --help this help
END_USAGE
}

sub run_editor {
    my ($self) = @_;

    my $app = Padre::App->new();
    $app->MainLoop;

    return;
}

sub _config_dir {
    my $dir = File::Spec->catfile(
        ($ENV{PADRE_HOME} ? $ENV{PADRE_HOME} : File::HomeDir->my_data),
        '.padre'
    );
    if ( not -e $dir ) {
        mkdir $dir or die "Cannot create config dir '$dir' $!";
    }
    return $dir;
}

sub config_dbh {
    my ($self) = @_;

    my $dir  = $self->_config_dir();
    my $path = File::Spec->catfile($dir, "config.db");
    my $new  = not -e $path;
    my $dbh  = DBI->connect("dbi:SQLite:dbname=$path", "", "", {
        RaiseError       => 1,
        PrintError       => 1,
        AutoCommit       => 1,
        FetchHashKeyName => 'NAME_lc',
    });
    if ( $new ) {
       $self->create_config($dbh);
    }
    return $dbh;
}

sub config_yaml {
    File::Spec->catfile( $_[0]->_config_dir, "config.yml" );
}

sub load_config {
    my ($self) = @_;

    my $dbh = $self->config_dbh();

    my $sth = $dbh->prepare("SELECT name FROM history WHERE type = ? ORDER BY id");

    foreach my $type (@history) {
        $sth->execute($type);
        #$Padre::Pod::Viewer::current = 0;
        while (my ($name) = $sth->fetchrow_array) {
            $self->add_to_recent($type, $name); 
        }
    }

    my $yaml = $self->config_yaml;
    if (-e $yaml) {
        $self->set_config(YAML::Tiny::LoadFile($yaml));
    }
    $self->set_defaults;

    return;
}

sub set_defaults {
    my ($self) = @_;

    my $config = $self->get_config;

    # number of moduls to display when searching for documentation
    $config->{DISPLAY_MAX_LIMIT} ||= 200;
    unless ( defined $config->{DISPLAY_MIN_LIMIT} ) {
        $config->{DISPLAY_MIN_LIMIT} = 2;
    }

    # size of the main window
    $config->{main}{height} ||= 600;
    $config->{main}{width}  ||= 700;

    # startup mode, if no files given on the command line this can be
    #   new        - a new empty buffer
    #   nothing    - nothing to open
    #   last       - the files that were open last time    
    $config->{startup} ||= 'new';

    unless ( defined $config->{search_terms} ) {
        $config->{search_terms} = [];
    }
    if ($config->{search_term}) {
       $config->{search_terms} = [ delete $config->{search_term} ]
    }

    $config->{command_line}      ||= '';
    # When running a script from the application some of the files might have not been saved yet.
    # There are several option what to do before running the script
    # none - don's save anything
    # same - save the file in the current buffer
    # all_files - all the files (but not buffers that have no filenames)
    # all_buffers - all the buffers even if they don't have a name yet
    $config->{save_on_run}       ||= 'same';

    $config->{show_line_numbers} ||= 0;

    $config->{projects}          ||= {};
    $config->{current_project}   ||= '';

    $self->set_config($config);
    return;
}

sub add_to_recent {
    my ($self, $type, $item) = @_;

    Carp::confess("No type given") if not $type;
    Carp::confess("Invalid type '$type'") if not grep {$_ eq $type} @history;

    my @recent = $self->get_recent($type);
    if (not grep {$_ eq $item} @recent) {
        push @recent, $item;
        @{ $self->{recent}{$type} } = @recent;
        $self->set_current_index($type, $#recent);
    }
    return;
}



sub get_recent {
    my ($self, $type) = @_;

    Carp::confess("No type given") if not $type;
    Carp::confess("Invalid type '$type'") if not grep {$_ eq $type} @history;

    return @{ $self->{recent}{$type} };
}

# gets a type, returns a name
sub get_current {
    my ($self, $type) = @_;

    Carp::confess("No type given") if not $type;
    Carp::confess("Invalid type '$type'") if not grep {$_ eq $type} @history;

    my $index = $self->get_current_index($type);
    return if not defined $index or $index == -1;
    return $self->{recent}{$type}[ $index ];
}

# gets a type, returns and index
sub get_current_index {
    my ($self, $type) = @_;

    Carp::confess("No type given") if not $type;
    Carp::confess("Invalid type '$type'") if not grep {$_ eq $type} @history;

    return $self->{current}{$type};
}
# gets a type and a name
sub set_current {
    my ($self, $type, $name) = @_;

    Carp::confess("No type given") if not $type;
    Carp::confess("Invalid type '$type'") if not grep {$_ eq $type} @history;

    foreach my $i (0.. @{ $self->{recent}{$type} } -1) {
        if ($self->{recent}{$type}[$i] eq $name) {
            $self->{current}{$type} = $i;
            last;
        }
    }
    return; 
}

# gets a type and a number
sub set_current_index {
    my ($self, $type, $n) = @_;

    Carp::confess("No type given") if not $type;
    Carp::confess("Invalid type '$type'") if not grep {$_ eq $type} @history;
    $self->{current}{$type} = $n;
    return; 
}


sub set_item {
    my ($self, $type, $number) = @_;

    my @recent = $self->get_recent($type);
    my $item = $recent[$number];
    $self->set_current_index('pod', $number);

    return $item;
}

sub remove_modules {
    my ($self) = @_;
    my $dbh = $self->config_dbh();
    $dbh->do("DELETE FROM modules");
    return;
}

sub add_modules {
    my ($self, @modules) = @_;

    my $dbh = $self->config_dbh();
    $dbh->begin_work;
    my $sth = $dbh->prepare("INSERT INTO modules (name) VALUES (?)");
    foreach my $m (@modules) {
        $sth->execute($m);
    }
    $dbh->commit;
    return;
}

sub get_modules {
    my ($self, $part) = @_;
    my $dbh = $self->config_dbh();
    #$dbh->prepare("SELECT name FROM modules ORDER BY name");
    #$dbh->execute;
    my $sql = "SELECT name FROM modules";
    my @bind_values;
    if ($part) {
        $sql .= " WHERE name LIKE ?";
        push @bind_values, '%' . $part .  '%';
    }
    $sql .= " ORDER BY name";
    #print "$sql\n";
    my $names = $dbh->selectcol_arrayref($sql, {}, @bind_values);

    return $names;
}

sub save_config {
    my ($self) = @_;

    my $dbh = $self->config_dbh();
    $dbh->do("DELETE FROM history");

    my $sth = $dbh->prepare("INSERT INTO history (type, name) VALUES (?, ?)");

    foreach my $type (@history) {
        foreach my $name ($self->get_recent($type)) {
            $sth->execute($type, $name);
        }
    }

    YAML::Tiny::DumpFile(
        $self->config_yaml,
        $self->get_config,
    );

    return;
}

sub create_config {
    my ($self, $dbh) = @_;
    $dbh->do("CREATE TABLE modules (id INTEGER PRIMARY KEY, name VARCHAR(100))");
    $dbh->do("CREATE TABLE history (id INTEGER PRIMARY KEY, type VARCHAR(100), name VARCHAR(100))");
    return;
} 

# returns the name of the next module
sub next_module {
    my ($self) = @_;

    my $current = $self->get_current_index('pod');
    return if not defined $current;

    my @current = $self->get_recent('pod');
    return if $current == $#current;
    $self->set_current_index('pod', $current + 1);

    return $self->get_current('pod');
}

# returns the name of the previous module
sub prev_module {
    my ($self) = @_;

    my $current = $self->get_current_index('pod');
    return if not defined $current;

    return if not $current;
    $self->set_current_index('pod', $current - 1);

    return $self->get_current('pod');
}

sub set_files {
    my ($self, @files) = @_;
    @{ $self->{_files} } = @files;

    return;
}
sub get_files {
    my ($self) = @_;
    return ($self->{_files} and ref ($self->{_files}) eq 'ARRAY' ? @{ $self->{_files} } : ());
}

sub set_widget {
    my ($self, $name, $value) = @_;
    $self->{widget}{$name} = $value;
    return;
}
sub get_widget {
    my ($self, $name) = @_;
    return $self->{widget}{$name};
}

=pod

=head1 BUGS

Please submit your bugs at L<http://padre.perlide.org/>

=head1 TODO

L<http://padre.perlide.org/>

=head2 Editor

  Fix the remaining short-cut key that don't work on Windows (F3)

  Deal with "resource installation". That is probably talk to
  Module::Build, Debian and Fedora people to make it easy to install resource files
  such as xpm or po files. See File::ShareDir.

=head2 Podviewer

  Enabled indexing from widthin application or run the indexer when installing
  the application?

  If a file exists but no pod in there, don't show just a white page.

  When displaying pod allow for clicking on names of other modules to be displayed.

  Indexing the words of all the pod files? (Search engine?)
  Indexing the function names only?

=head2 Code layout:

Padre is the main module that reads/writes the configuration files
There is an SQLite database and a yml file to keep various pices of information
The SQLite database holds the list of modules available on the system.
It will also contain indexing of the documentation
Looking at the X<> entries of modules
List of functions

The yml file contains individual configuration options

Padre::App is the Wx::App subclass

Padre::Frame is the main frame, most of the code is currently there.

Padre::Panel holds an editor window instance (one for each buffer)

Padre::Pod::* are there to index and show documentation written in pod.

=head1 SUPPORT

I hope the L<http://www.perlmonks.org/> will be ready to take
upon themself supporting this application.

See also L<http://padre.perlide.org/>

=head1 COPYRIGHT

(c) 2008 Gabor Szabo http://www.szabgab.com/

=head1 LICENSE

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl 5 itself.


=head1 WARRANTY

There is no warranty whatsoever.
If you lose data or your hair because of this program,
that's your problem.

=head1 CREDITS and THANKS

To Mattia Barbon for providing WxPerl.
Part of the code was copied from his Wx::Demo application.

To Herbert Breunung for leting me work on Kephra.

To Octavian Rasnita for early testing and bug reports.

=cut

1;

