package Padre;

=pod

=head1 NAME

Padre - Perl Application Development and Refactoring Environment

=head1 SYNOPSIS

Padre is a text editor aimed to be an IDE for Perl.

You should be able to just type in 

  padre

and get the editor working.

While I have been using this editor since version 0.01 myself there 
are still lots of missing features.

Not only it is missing several important feature, everything is in
a constant flux. Menus, shortcuts and the way they work will change
from version to version.

Having said that you can already use it for serious editing and you
can even get involved and add the missing features.

You should also know that I am mostly working on Linux and I
have been using vi for many years now. This means that I am 
not that familiar with the expectations of people using 
Windows.

=head1 FEATURES

Instead of duplicating all the text here, let me point you to the
web site of Padre L<http://padre.perlide.org/> where we keep a list
of existing and planned features.

=head1 DESCRIPTION

The application maintains its configuration information in a 
directory called F<.padre>.

On Strawberry Perl you can associate .pl file extension with
C:\strawberry\perl\bin\wxperl and then you can start double 
clicking on the application. It should work...

  Run This (F5) - run the current buffer with the current perl
  this currently only works with files with .pl  extensions.
  
  Run Any (Ctr-F5) - run any external application
  First time it will prompt you to a command line that you have to
  type in such as
  
  perl /full/path/to/my/script.pl

...then it will execute this every time you press Ctrl-F5 or the menu
option. Currently Ctrl-F5 does not save any file.
(This will be added later.)

You can edit the command line using the Run/Setup menu item.

  Ctr-1          matching brace
  Ctr-P          Autocompletition
  Alt-N          Nth Pane
  Ctr-TAB        Next Pane
  Ctr-Shift-TAB  Previous Pane
  Alt-S          Jump to list of subs window
  
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


=head1 Search, Find and Replace

(planning)


=head2 Search

Ctrl-F opens the search window, if something was selected then that is given as the search text.
Otherwise the last search string should be displayed.

Provide option to search backwards

Limit action to current block, current subroutine, current
file (should be the default) current project, current directory 
with some file filters.

When the user presses Find

=over 4

=item 1

We find the first hit and the search window disappears. F3 jumps to next one.

=item 2

The first match is highlighted and focused but the window stays
When the user clicks on the Find button again, we jump to the next hit
In this case the user must be able to edit the document while the search window
is on.

=item 3

All the matches are highlighted and we go to the first match, window disappears.
F3 jumps to next one

=item 4

All the matches are highlighted and we go to the first one, window stays open
user can edit text

=back

=head2 Find and Replace

Find - find the next occurance

Replace all - do just that

Replace - if currently a match is selected then replace it find the next occurance and select it

=head2 TODO describe what to do if we have to deal with files that are not in the editor

if "Replace all" was pressed then do just that 
   1) without opening editors for the files.
   2) opening an editor for each file and keep it in unsaved state (sounds carzy having 1000 editors open...)
if Search or Replace is clicked then we might show the next location in the lower pane. 
If the user then presses Replace we open the file in an editor window and go on.
If the user presses Search then we show the next occurance.
Opened and edited files will be left in a not saved state.

=cut

use 5.008;
use strict;
use warnings;
use Carp           ();
use File::Spec     ();
use File::HomeDir  ();
use Getopt::Long   ();
use YAML::Tiny     ();
use DBI            ();
use Class::Autouse ();

our $VERSION = '0.11';

# Since everything is used OO-style,
# autouse everything other than the bare essentials
use Padre::Util           ();
use Padre::Config         ();
use Padre::DB             ();
use Padre::Wx::App        ();
use Padre::Wx::MainWindow ();

# Nudges to make Class::Autouse behave
BEGIN {
	$Class::Autouse::LOADED{'Wx::Object'} = 1;
}
use Class::Autouse qw{
	Padre::DB
	Padre::Document
	Padre::Document::Perl
	Padre::Project
	Padre::PluginManager
	Padre::Pod::Frame
	Padre::Pod::Indexer
	Padre::Pod::Viewer
	Padre::Wx::Popup
	Padre::Wx::Editor
	Padre::Wx::Menu
	Padre::Wx::Menu::Help
	Padre::Wx::Ack
	Padre::Wx::Bookmarks
	Padre::Wx::FindDialog
	Padre::Wx::GoToLine
	Padre::Wx::ModuleStartDialog
};

# Globally shared Perl detection object
sub perl_interpreter {
	require Probe::Perl;
	return Probe::Perl->find_perl_interpreter;
}

my @history = qw(files pod);

my $SINGLETON = undef;
sub inst {
	Carp::croak("Padre->new has not been called yet") if not $SINGLETON;
	return $SINGLETON;
}
sub new {
	Carp::croak("Padre->new already called. Use Padre->inst") if $SINGLETON;
	my $class = shift;

	# Create the empty object
	my $self = $SINGLETON = bless {
		# Wx Attributes
		wx          => undef,

		# Internal Attributes
		config_dir  => undef,
		config_yaml => undef,

		# Plugin Attributes
		plugin_manager => undef,

		# Second-Generation Object Model
		# (Adam says ignore these for now, but don't comment out)
		project  => {},
		document => {},

	}, $class;

	# Locate the configuration
	$self->{config_dir}  = Padre::Config->default_dir;
	$self->{config_yaml} = Padre::Config->default_yaml;
	$self->{config}      = Padre::Config->read(   $self->config_yaml );
	$self->{config}    ||= Padre::Config->create( $self->config_yaml );

	$self->{plugin_manager} = Padre::PluginManager->new($self);

	# Load the database
	Class::Autouse->load('Padre::DB');

	return $self;
}

sub ide {
	$SINGLETON or
	$SINGLETON = Padre->new;
}

sub wx {
	my $self = shift;
	$self->{wx} or
	$self->{wx} = Padre::Wx::App->new;
}

sub config {
	$_[0]->{config};
}

sub config_dir {
	$_[0]->{config_dir};
}

sub config_yaml {
	$_[0]->{config_yaml};
}

sub plugin_manager {
	$_[0]->{plugin_manager};
}

sub run {
	my $self = shift;

	my %opt;
	Getopt::Long::GetOptions(\%opt, "index", "help") or usage();
	usage() if $opt{help};

	# Launch the indexer if requested
	return $self->run_indexer if $opt{index};

	# FIXME: This call should be delayed until after the
	# window was opened but my Wx skills do not exist. --Steffen
	# (RT #1)
	$self->plugin_manager->load_plugins;
	$self->{ARGV} = \@ARGV;

	return $self->run_editor;
}

sub run_indexer {
	my ($self) = @_;

	# Run the indexer
	require Padre::Pod::Indexer;
	my $indexer = Padre::Pod::Indexer->new;
	my @files   = $indexer->list_all_files(@INC);

	# Save to the database
	Padre::DB->begin;
	Padre::DB->remove_modules;
	Padre::DB->add_modules(@files);
	Padre::DB->commit;

	return;
}

sub run_editor {
	my $self = shift;

	$self->wx->MainLoop;
	$self->{wx} = undef;
	return;
}

# Save the YAML configuration file
sub save_config {
	$_[0]->config->write( $_[0]->config_yaml );
}

# returns the name of the next module
sub next_module {
	my ($self) = @_;

	# Temporarily breaking the next and back buttons
	# my $current = $self->get_current_index('pod');
	# return if not defined $current;
	#
	# my @current = Padre::DB->get_recent_pod;
	# return if $current == $#current;
	# $self->set_current_index('pod', $current + 1);

	return Padre::DB->get_last_pod;
}

# returns the name of the previous module
sub prev_module {
	my ($self) = @_;

	# Temporarily breaking the next and back buttons
	# my $current = $self->get_current_index('pod');
	# return if not defined $current;
	#
	# return if not $current;
	# $self->set_current_index('pod', $current - 1);

	return Padre::DB->get_last_pod;
}

sub usage { print <<"END_USAGE"; exit(1) }
Usage: $0 [FILENAMEs]
           --index to index the modules found on this computer
           --help this help
END_USAGE

1;

=pod

=head1 BUGS

Please submit your bugs at L<http://padre.perlide.org/>

=head1 Code layout

Padre is the main module that reads/writes the configuration files
There is an SQLite database and a yml file to keep various pices of information
The SQLite database holds the list of modules available on the system.
It will also contain indexing of the documentation
Looking at the X<> entries of modules
List of functions

The yml file contains individual configuration options

Padre::Wx::App is the Wx::App subclass

Padre::Wx::MainWindow is the main frame, most of the code is currently there.

Padre::Wx::Editor holds an editor text control instance
(one for each buffer/file)

Padre::Pod::* are there to index and show documentation written in pod.

=head1 SUPPORT

I hope the L<http://www.perlmonks.org/> will be ready to take
upon themself supporting this application.

See also L<http://padre.perlide.org/>

=head1 COPYRIGHT

Copyright 2008 Gabor Szabo. L<http://www.szabgab.com/>

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

To Adam Kennedy for lots of refactoring.

To Steffen Müller for PAR plugins.

To Patrick Donelan.

To Herbert Breunung for letting me work on Kephra.

To Octavian Rasnita for early testing and bug reports.

=cut
