package Padre;

# See POD at end for documentation

use 5.008005;
use strict;
use warnings;
use utf8;

# Non-Padre modules we need in order to do the single-instance
# check should be loaded early to simplify the load order.
use Carp          ();
use Cwd           ();
use File::Spec    ();
use File::HomeDir ();
use List::Util    ();
use Scalar::Util  ();
use Getopt::Long  ();
use YAML::Tiny    ();
use DBI           ();
use DBD::SQLite   ();

# load this before things are messed up to produce versions like '0,76'!
# TO DO: Bug report dispatched. Likely to be fixed in 0.77.
use version ();

our $VERSION = '0.56';

# Since everything is used OO-style, we will be require'ing
# everything other than the bare essentials
use Padre::Constant ();
use Padre::Config   ();
use Padre::DB       ();
use Padre::Action::Queue;

# Generate faster accessors
use Class::XSAccessor {
	getters => {
		original_cwd   => 'original_cwd',
		opts           => 'opts',
		config         => 'config',
		wx             => 'wx',
		task_manager   => 'task_manager',
		plugin_manager => 'plugin_manager',
	},
	accessors => {
		actions     => 'actions',
		instance_id => 'instance_id',
	},
};

sub import {
	unless ( $_[1] and $_[1] eq ':everything' ) {
		return;
	}

	# Find the location of Padre.pm
	my $padre = $INC{'Padre.pm'};
	my $parent = substr( $padre, 0, length($padre) - 3 );

	# Find everything under Padre:: with a matching version,
	# which almost certainly means it is part of the main Padre release.
	require File::Find::Rule;
	require ExtUtils::MakeMaker;
	my @children = grep { not $INC{$_} }
		map {"Padre/$_->[0]"}
		grep { defined( $_->[1] ) and $_->[1] eq $VERSION }
		map { [ $_, ExtUtils::MM_Unix->parse_version( File::Spec->catfile( $parent, $_ ) ) ] }
		File::Find::Rule->name('*.pm')->file->relative->in($parent);

	# Load all of them (ignoring errors)
	my $loaded = 0;
	my %skip = map { $_ => 1 } qw{
		Padre/CPAN.pm
		Padre/Test.pm
	};
	foreach my $child (@children) {

		# Evil modules we should avoid
		next if $skip{$child};

		# We are not permitted to tread in plugin territory
		next if $child =~ /^Padre\/Plugin\//;

		eval { require $child; };
		next if $@;
		$loaded++;
	}

	return $loaded;
}

my $SINGLETON = undef;

# Access to the Singleton post-construction
sub ide {
	$SINGLETON or Carp::croak('Padre->new has not been called yet');
}

# The order of initialisation here is VERY important
sub new {
	Carp::croak('Padre->new already called. Use Padre->ide') if $SINGLETON;
	my $class = shift;
	my %opts  = @_;

	# Create the empty object
	my $self = $SINGLETON = bless {

		# Parsed command-line options
		opts => \%opts,

		# Wx Attributes
		wx => undef,

		# Plug-in Attributes
		plugin_manager => undef,

		# Project Attributes
		project => {},

	}, $class;

	# Create our instance ID:
	for ( 1 .. 64 ) {
		$self->{instance_id} .= chr( ( 48 .. 57, 65 .. 90, 97 .. 122 )[ int( rand(62) ) ] );
	}

	# Save the start-up dir before anyone can move us.
	$self->{original_cwd} = Cwd::cwd();

	# Set up a raw (non-Padre::Locker) transaction around the rest of the constructor.
	Padre::DB->begin;

	# Load (and sync if needed) the configuration
	$self->{config} = Padre::Config->read;

	# Actions registry
	my %actions = ();
	$self->actions( \%actions );

	# Load a few more bits and pieces now we know
	# that we'll need them
	require Padre::Project;

	# Create the plugin manager
	require Padre::PluginManager;
	$self->{plugin_manager} = Padre::PluginManager->new($self);

	# Create the main window
	require Padre::Wx::App;
	$self->{wx} = Padre::Wx::App->new($self);

	# Create the task manager
	require Padre::TaskManager;
	$self->{task_manager} = Padre::TaskManager->new(
		use_threads => $self->config->threads,
	);

	# Create the action queue
	$self->{actionqueue} = Padre::Action::Queue->new();

	# Startup completed, let go of the database
	Padre::DB->commit;

	return $self;
}

sub run {
	my $self = shift;

	# Allow scripts to detect that they are being executed within Padre
	local $ENV{PADRE_VERSION} = $VERSION;

	# Clean arguments (with a bad patch for saving URLs)
	if (Padre::Constant::WIN32) {

		# Windows has trouble deleting the work directory of a process,
		# so reset file to full path
		$self->{ARGV} = [
			map {
				if (/\:/) { $_; }
				else {
					File::Spec->rel2abs( $_, $self->{original_cwd} );
				}
				} @ARGV
		];
	} else {
		$self->{ARGV} = \@ARGV;
	}

	# FIX ME: RT #1 This call should be delayed until after the
	# window was opened but my Wx skills do not exist. --Steffen
	SCOPE: {

		# Lock rendering and the database while the plugins are loading
		# to prevent them doing anything weird or slow.
		my $lock = $self->wx->main->lock('DB');
		$self->plugin_manager->load_plugins;
	}

	# Move our current dir to the user's documents directory by default
	if (Padre::Constant::WIN32) {

		# Windows has trouble deleting the work directory of a process,
		# so we change the working dir
		my $documents = File::HomeDir->my_documents;
		if ( defined $documents ) {
			chdir $documents;
		}
	}

	# Check if we have Time::HiRes:
	# This should be better done in a background job
	if ( eval { require Time::HiRes; } and ( !$@ ) ) {
		$self->{has_Time_HiRes} = 1;
	}

	# HACK: Uncomment this to locate difficult-to-find crashes
	#       that are throw silent exceptions.
	# local $SIG{__DIE__} = sub { print @_; die $_[0] };

	# Kill the splash screen
	if ($Padre::Startup::VERSION) {
		Padre::Startup->destroy_splash;
	}

	# Process the action queue
	if ( defined $self->opts->{actionqueue} ) {
		for my $action ( split( /\,/, $self->opts->{actionqueue} ) ) {
			next if $action eq ''; # Skip empty action names
			unless ( defined $self->actions->{$action} ) {
				warn 'Action "$action" queued from command line but does not exist';
				next;
			}

			# Add the action to the queue
			$self->{actionqueue}->add($action);
		}
	}

	# Switch into runtime mode
	$self->wx->MainLoop;

	# All shutdown procedures complete.
	# Do some final cleaning up.
	$self->{wx} = undef;

	return;
}

# Save the YAML configuration file
sub save_config {
	$_[0]->config->write;
}





#####################################################################
# Project Management

sub project {
	my $self = shift;
	my $root = shift;
	unless ( $self->{project}->{$root} ) {
		my $nofile = File::Spec->catfile( $root, 'a' );
		$self->{project}->{$root} = Padre::Project->from_file($nofile);
	}
	return $self->{project}->{$root};
}

1;

__END__

=pod

=head1 NAME

Padre - Perl Application Development and Refactoring Environment

=head1 SYNOPSIS

Padre is a text editor aimed to be an IDE for Perl.

After installation you should be able to just type in

  padre

and get the editor working.

Padre development started in June 2008 and made a lot of progress but
there are still lots of missing features and the development is still
very fast.

=head1 Getting Started

After installing Padre you can start it by typing B<padre> on the command line.
On Windows that would be Start/Run padre.bat

(TO DO) By default Padre starts with an editor containing a simple Perl script
and instructions.

You can edit the file and save it using File/Save (C<Ctrl+S>).

You can run the script by pressing Run/Run Script (C<F5>)

You can start new files File/New (C<Ctrl+N>)
or open existing files File/Open (C<Ctrl+O>).

By default Padre uses the same Perl interpreter for
executing code that it uses for itself but this will be configurable
later.

=head1 FEATURES

Instead of duplicating all the text here, let me point you to the
web site of Padre L<http://padre.perlide.org/> where we keep a list
of existing and planned features.

=head1 DESCRIPTION

=head2 Configuration

The application maintains its configuration information in a
directory called F<.padre>.

=head2 Files operations

B<File/New> creates a new empty file. By default Padre assumes this is a Perl script.
(TO DO later this default will be configurable).

B<File/Open> allows you to browse for a file and select it for opening.

B<File/Open Selection>, (C<Ctrl+Shift+O>) if there is a selected text this will
try to locate files that match the selection. If the selection looks like a path
Padre will try to open that path either absolute or relative.
If it looks like a module name (Some::Thing) it will try to find the appropriate file Some/Thing.pm in @INC and open it.
currently this feature opens the first file encountered.
(TO DO it should find all the possibilities and if there are multiple hits
offer the user to choose. This will be especially important if we are
working on a module that is also already installed. Padre might
find the installed version first while we might want to open the
development version.)

(TO DO: when the file is not of Perl type we should have other ways to recognize
files from internal naming and have paths to search. Surprise, not every
language uses @INC.)

B<File/Close> - checks if the file is saved, if it is closes the current tab.

B<File/Close All> - closes all opened files (in case they are not saved yet ask for instructions).

B<File/Close All but Current> - closes all opened files except for the currently being edited.

B<File/Reload File> - Reloads the file. This is interesting if you either made changes and want to discard them
and/or if the file has changed on the disk. If there are unsaved changes Padre will ask
you if you really want to throw them away. (TO DO: make a backup of the file before discarding it)

B<File/Save> C<Ctrl+S> - save the current file. If the buffer is not yet saved and has no file name associated with it, Padre will ask you for a file name.

B<File/Save As> - Offer the user to select a new file name and save the content under that name.

B<File/Save All> - Save all the currently opened files.

B<File/Convert> - Convert line endings to Windows, Unix or Mac Classic style.

B<Files/Recent Files> - a list of recently opened files to open them easily.
(TO DO: update the list when we open a file, not only when opening padre)
(TO DO: allow the user to configure size of history)

B<File/Doc Stats> - just random statistics about the current document.
(TO DO: If you miss anything important let us know!)

B<File/Quit> - Exits Padre.

=head2 Simple editing

The simple editing features (should) provide the expected behavior
for Windows users.

B<Edit/Undo> C<Ctrl+Z>

B<Edit/Redo>

B<Edit/Select All> C<Ctrl+A>, select all the characters in the current document

B<Edit/Copy> C<Ctrl+C>

B<Edit/Cut> C<Ctrl+X>

B<Edit/Paste> C<Ctrl+V>

(TO DO What is C<Ctrl+D> ?, duplicate the current line?)

=head2 Mouse right click

Click on the right button of the mouse brings up a context sensitive menu.
It provides the basic editing functions and will provide other context
sensitive options.

=head2 Projects (TO DO)

Padre will have the notion of a Perl project. As we would like
to make things as natural as possible for the Perl developer
and we think the distribution methods used for C<CPAN> module are
a good way to handle any project Padre will understand a project
as a C<CPAN> module. This does not mean that your project needs to end
up on C<CPAN> of course. But if your projects directory structure
follows that of the modules on C<CPAN>, Padre will be automatically
recognize it.

=head2 Module::Starter

As a first step in the direction of supporting C<CPAN>-style Perl
projects we integrated into Padre the use of L<Module::Starter>

B<File/New.../Perl Distribution> will bring up a dialog box where
you can select some of the parameters your new project has such
as Name of the Project (e.g. My::Widgets), Author - that is probably
your name, e-mail (your e-mail).

Builder is the tool that you project is going to use to package itself
and then your user will use to install the project.
Currently L<Module::Build> and L<ExtUtils::MakeMaker> are supported.
(TO DO add Module::Install as well).

License is one of the keywords currently listed in the F<META.yml> spec of
Module::Build. (TO DO: update the list or make it dynamic)

Once you click B<OK>, Module::Starter will create a new
directory called My-Widgets in the parent directory you selected
in the last field.

=head2 Other

On Strawberry Perl you can associate .pl file extension with
F<C:\strawberry\perl\bin\wxperl> and then you can start double
clicking on the application. It should work...

Run This (C<F5>) - run the current buffer with the current Perl
this currently only works with files with F<.pl> extensions.

Run Any (C<Ctrl+F5>) - run any external application

First time it will prompt you to a command line that you have to
type in such as

  perl /full/path/to/my/script.pl

...then it will execute this every time you press C<Ctrl+F5> or the menu
option. Currently C<Ctrl+F5> does not save any file.
(This will be added later.)

You can edit the command line using the Run/Setup menu item.

Please Note that you can use C<$ENV{PADRE_VERSION}> to detect whether the script
is running inside Padre or not.

=head2 Bookmarks

B<View/Set Bookmark> (C<Ctrl+B>) brings up a window with a
predefined text containing the file name and line number
(TO DO should be the content of the current line).

B<View/Go to Bookmark> (C<Ctrl+Shift+B>) brings up a window with the
list of available bookmarks. You can select one and press B<OK>
to jump to that location. If the file where the bookmark belongs
to is not open currently, it will be opened and the cursor will
jump to the desired place.

In both cases while the window is open you can select
existing bookmarks and press the B<Delete> button to remove the
selected one or press B<Delete All> to remove all the existing
bookmarks.

=head2 Navigation

  Ctrl+G          Go to Line
  Ctrl+1          Matching Brace
  Ctrl+2          Quick Fix
  Ctrl+.          Next Problem
  Ctrl+P          Word Auto-completion
  Alt+N           Nth Pane
  Ctrl+Tab        Next Pane
  Ctrl+Shift+Tab  Previous Pane
  Alt+S           Jump to list of subs window

  Ctrl+M Ctrl+Shift+M  comment/uncomment selected lines of code

  Ctrl+H opens a help window where you can see the documentation of
  any Perl module. Just use open (in the help window) and type in the name
  of a module.

  Ctrl+Shift+H Highlight the name of a module in the editor and then
  press Ctrl+Shift+H. It will open the help window for the module
  whose name was highlighted.

  In the help window you can also start typing the name of a module. When the
  list of the matching possible modules is small enough you'll be able
  to open the drop-down list and select the name.
  The "small enough" is controlled by two configuration options in the
  Edit/Setup menu:

  Max Number of modules
  Min Number of modules

  This feature only works after you have indexed all the modules
  on your computer. Indexing is currently done by running the following command:

  padre --index

=head2 Rectangular Text Selection

Simple text editors usually only allow you to select contiguous lines of text with your mouse.
Sometimes, however, it is handy to be able to select a rectangular area of text for more precise
cutting/copying/pasting or performing search/replace on. You can select a rectangular area in Padre
by holding down C<Ctrl+Alt> whilst selecting text with your mouse.

For example, imagine you have the following nicely formatted hash assignment in a Perl source file:

  my %hash = (
      key1 => 'value1',
      key2 => 'value2',
      key3 => 'value3',
 );

With a rectangular text selection you can select only the keys, only the values, etc..

=head2 Syntax highlighting

Padre is using L<Wx> (aka wxPerl), wxWidgets for GUI and Scintilla for the editor.
Scintilla provides very good syntax highlighting for many languages but Padre is still
bound by the version of Scintilla included.

The F<share/styles/default.yml> file is the mapping between the Scintilla defined
constants for various syntactical elements of each language and the C<RGB> values
of the color to be used to highlight them.

=head3 Adding new syntax highlighting

To set up a custom syntax highlighting scheme, you create a F<.yml> file that defines
the mappings described above. The easiest way to create your own scheme is probably to copy an existing
F<.yml> file (for instance, F<default.yml>) from the F<share/styles/> folder, put it in
F<~/.padre/styles>, and then modify it. Padre checks this folder on start-up and adds
any styles in the F<.yml> files there to the C<< View -> Style >> menu.

TO DO does this stuff below really belong here?

Need to define constants in L<Padre::Util> to be in the C<Padre::Constant> namespace.

Need to add the color mapping to F<share/styles/default.yml>

Need to implement the C<Padre::Document::Language> class.

Need to define the MIME type mapping in L<Padre::Document>

For examples see L<Padre::Document::PASM>, L<Padre::Document::PIR>,
L<Padre::Document::Perl>.

=head2 Syntax checking

Depending on a corresponding support in the respective C<Padre::Document::Language>
class, Padre supports real time syntax checking capabilities:

=over 4

=item

Syntax errors or warnings are displayed in a side bar (usually at the bottom of the
Padre window). By double-clicking a list entry you can navigate to the position in
the file.

=item

Additionally, there is a symbol column on the left side of the editor where colored
symbols mark the code lines with problems.

=back

=head3 WARNING NOTE

Syntax checking for Perl5 documents comes bundled with Padre. It is implemented
using C<perl -c>. This means that parts of the code actually get executed (e.g.
C<BEGIN> blocks). Malicious software might used this fact to damage your system
(C<BEGIN { system('rm -rf ~') }>) or suck up your resources
(C<BEGIN { while(1) { } }>).
Syntax checking is currently disabled by default and has to be enabled manually
after every start of Padre. This somewhat increases security when doing
C<padre some_unknown_file.pl>.
However, it does not protect you when you open a file from within Padre while
syntax checking is turned on.
The most secure solution would require a really fast non-executing syntax checker
which unfortunately is currently not available.

=head1 Preferences

There are several types of preferences we can think of.
There are the current view printed preferences such as B<Show newlines>
or B<Show Line numbers> and there are the project and file
oriented preferences such as the use of tabulators or white space
for indentation.

We would like to achieve that the

Currently some of the preferences are accessible via the
B<Edit/Preferences> menu options, others via the B<View>
menu option.

We have to make sure that when changing the preferences via
the GUI it change for the correct things.

E.g. when changing the B<Use Tabulators> preference it currently
applies to all the files open currently or in the future.
It should probably apply to the current file and/or the
current project. Such options - when changing them - might even
be applied "retroactively". That is when I change the tabulator/space
mode of a file or a project it should ask if I want to reflow the
file with the new method of indentation?

On the other hand the "Tabulator display size" is purely a local, editor
oriented preference. It should probably apply to all files currently
open.

There are other aspects of preferences as well that might not exactly
overlap with the above set:

The developer might work on the same project on different machines.
In such case some of the personal preferences should apply only
only on one computer while others apply in both places.

In particular if Padre is installed in a Portable Perl it might
run on machines with different parameters. Screen size and resolution
might be different along other parameters. We would like to make sure
the relevant preferences are separated from those that are constant
even when moving between computers.

=head2 Editor or view oriented preferences

=over 4

=item Size and location of windows

=item Show/Hide various windows, Status bar, Toolbar

=item Files recently opened

=item Files that were open last time, cursor location

=item Show newlines

=item Show Line numbers

=item Show indentation guide

B<View/Show Indentation Guide>

When set, Padre will display a thin vertical line at every indentation
level on every row with are indented more than one level.

=item Highlight indentation guide (TO DO)

This should be a separate option available only
if the C<Show indentation guide> and brace matching is on.

If C<SetHighlightGuide> is set to 8 then when the user reaches one
side of a pair of braces the indentation guide - if there is one
on column 8 - will be highlighted. (in green).

As I understand Padre should constantly adjust the C<SetHighlightGuide>
so that in every block the "correct" indentation guide is highlighted.

=item Show Call Tips

=item Tabulator display size

=item Allow experimental features

In order to allow the experimental features one needs to manually turn on the
experimental flag to 1 in F<config.yml>. As Padre keeps overwriting this file you'll
have to make this change with another editor and while Padre is B<not> open.

The F<config.yml> file is in F<~/.padre/> on Linux/Unix and in general in
your home directory on Windows. In any case the B<Help/About> box will show
you the path of the F<.padre> directory of Padre.

Once you set the experimental flag when you start Padre you will see a new
menu on the right side of the menu bar called B<Experimental>.

=item Open file policy

What files to open when launching Padre?
nothing, new, those that were open last time?

=item Max/Min number of modules to display in POD viewer

=item Auto-indentation

Possible values: no/same level/deep

There are at least two levels of auto-indentation:

1) when ENTER is pressed indent to exactly the same level as the previous line

2) if there is an opening brace { on the previous line, indent one level more

=item Brace matching

When the cursor reaches an opening or closing brace { }, square bracket [ ]
or parentheses ( ), Padre automatically highlight the pair of the braces.

TO DO make this optional, let the user set the color

=item Auto-save on/off?

=back

=head2 File and Project oriented preferences

=over 4

=item Indentation should be by tabulators or spaces

=item In case of using spaces for indentation, the width  of every indentation level

=back

=head1 Other features

=head2 Auto-backup (Planned)

See L<Padre::Autosave>

When Padre opens a file it automatically creates a copy of the original
in F<~/.padre/backup/PATH>  where PATH is the same PATH as the full PATH of
the file. On Windows the initial drive letter is converted to another
subdirectory so F<c:\dir\file.txt>  will be saved as
F<~/padre/backup/c/dir/file.txt>.

When a new file is created no need for auto-backup.

When a remote file is opened the backup will probably go to
F<~/padre/backup_remote/>

Configurable options: on/off

=head2 Auto-save files (Planned)

Every N seconds all the files changed since the last auto-save are
saved to a temporary place maybe F<~/.padre/save>.

When the user closes the file, the auto-saved file is removed.

Configurable options: on/off, frequency in seconds

=head1 SQLite

Padre is using an SQLite database (F<~/.padre/config.db>) for two
things.
Part of the preferences/configuration information is kept there
and it is used for the POD reader.

=head1 Documentation POD reader

Padre currently can index (the names of) all the modules on
your system and it was planned to have a search capability for
modules/functions/etc.

=head1 Plug-ins

There is a highly experimental but quite simple plug-in system.

A plug-in is a module in the C<Padre::Plugin::*> namespace.

At start-up time Padre looks for all such modules in C<@INC> and
in its own private directory and loads them.

Every plug-in must be a subclass of L<Padre::Plugin> and follow the rules
defined in the L<Padre::Plugin> API documentation.

See also L<Padre::PluginManager> and L<Padre::PluginBuilder>

While Padre is running there is a menu option to show the plug-in configuration
window that shows the list of all the plug-ins.

TO DO: What to do if a newer version of the same plug-in was installed?

TO DO: What to do if a module was removed ? Shall we keep its data in
the configuration file or remove it?

TO DO: Padre should offer an easy but simple way for plug-in authors
to declare configuration variables and automatically generate both configuration
file and configuration dialog. Padre should also allow for full customization
of both for those more advanced in Wx.

=head1 Editing tools

=head2 Case Changes

Change the case of the selected text or if there
is no selection all the text in the current file.

Change all characters to upper or lower case

Change the first character of every word to upper/lower
case leaving the rest as they were.

=head2 Tab and space conversion

Tab to Space and Space to Tab conversions ask the number of spaces
each tab should substitute. It currently works everywhere.
We probably should add a mode to operate only at the beginning of
the lines or better yet only at the indentation levels.

Delete All Ending space does just what it says.

Delete Leading Space will ask How many leading spaces and act accordingly.


=head1 Search, Find and Replace

(planning)

=head2 Search

C<Ctrl+F> opens the search window, if something was selected then that is given as the search text.
Otherwise the last search string should be displayed.

Provide option to search backwards

Limit action to current block, current subroutine, current
file (should be the default) current project, current directory
with some file filters.

When the user presses Find

=over 4

=item 1

We find the first hit and the search window disappears. C<F3> jumps to next one.

=item 2

The first match is highlighted and focused but the window stays
When the user clicks on the Find button again, we jump to the next hit
In this case the user must be able to edit the document while the search window
is on.

=item 3

All the matches are highlighted and we go to the first match, window disappears.
C<F3> jumps to next one

=item 4

All the matches are highlighted and we go to the first one, window stays open
user can edit text

=back

=head2 Find and Replace

Find - find the next occurrence

Replace all - do just that

Replace - if currently a match is selected then replace it find the next occurrence and select it

=head2 TO DO describe what to do if we have to deal with files that are not in the editor

if "Replace all" was pressed then do just that
   1) without opening editors for the files.
   2) opening an editor for each file and keep it in unsaved state (sounds crazy having 1000 editors open...)
if Search or Replace is clicked then we might show the next location in the lower pane.
If the user then presses Replace we open the file in an editor window and go on.
If the user presses Search then we show the next occurrence.
Opened and edited files will be left in a not saved state.

=head1 Code layout

=over 4

=item Padre.pm

is the main module.

=item L<Padre::Autosave>

describes some of our plans for an auto-save mechanism.
It is not implemented yet. (There is also some description elsewhere in this
document).

=item L<Padre::Config>

reads/writes the configuration files.

There is an SQLite database and a YAML file to keep various pieces of information.
The database holds host related configuration values while the YAML file holds
personal configuration options.

The SQLite database holds the list of modules available on the system.
It will also contain indexing of the documentation
Looking at the C<X<>> entries of modules
List of functions

=item L<Padre::DB>

The SQLite database abstraction for storing Padre's internal data.

=item L<Padre::Document>

is an abstraction class to deal with a single document.

=over 4

=item L<Padre::Document::PASM>

=item L<Padre::Document::PIR>

=item L<Padre::Document::Perl>

=back

=item L<Padre::PluginBuilder>

=item L<Padre::PluginManager>

locates and loads the plug-ins.

=item L<Plugin>

Should be the base class of all plug-ins.

=item L<Padre::Pod2HTML>

=item L<Padre::PPI>

=item L<Padre::Project>

Abstract class understanding what a project is.

=item L<Padre::Project::Perl>

Is a Perl specific project. These are work in process.
Not yet used.

=item L<Padre::TaskManager>

Managing background tasks.

=item L<Padre::Task>

Background tasks.

=item L<Padre::Util>

Various utility functions.

=back

=head2 Wx GUI

The C<Padre::Wx::*> namespace is supposed to deal with all the
Wx related code. Outside of that the code is not supposed to
know about Wx, but currently it still does.

=over 4

=item L<Padre::Wx>

=item L<Padre::Wx::Ack>

Implementation of the L<ack> integration in Edit/Ack menu item.
It probably should be either under Dialog or moved out to be a
plug-in.

=item L<Padre::Wx::App>

is the L<Wx::App> subclass. Does not really do much.

=item L<Padre::Wx::Dialog>

is the parent class of all the major dialogs
that are all implemented in modules in the C<Padre::Wx::Dialog::*>
namespace. It is actually a plain subclass of L<Wx::Perl::Dialog>.

=over 4

=item L<Padre::Wx::Dialog::Bookmarks>

=item L<Padre::Wx::Dialog::Find>

Current Find and Replace widget.

=item L<Padre::Wx::Dialog::ModuleStart>

L<Module::Start> integration. Maybe it should be moved to be a plug-in.

=item L<Padre::Wx::Dialog::PluginManager>

=item L<Padre::Wx::Dialog::Preferences>

=item L<Padre::Wx::Dialog::Search>

This is the newer Firefox like search box. Not yet integrated.

=item L<Padre::Wx::Dialog::Snippets>

=back

=item L<Padre::Wx::FileDropTarget>

The code for drag and drop

=item L<Padre::Wx::Editor>

holds an editor text control instance (one for each buffer/file).
This is a subclass of L<Wx::StyledTextCtrl> also known as C<STC> or
Scintilla.

=item L<Padre::Wx::History::ComboBox>

=item L<Padre::Wx::History::TextEntryDialog>

=item L<Padre::Wx::Main>

This is the main window, most of the code is currently there.

=item L<Padre::Wx::Menu>

handles everything the menu should know and do.

=item L<Padre::Wx::Output>

the output window at the bottom of the editor displaying the output
of running code using C<F5>.

=item L<Padre::Wx::HtmlWindow>

=item L<Padre::Wx::PodFrame>

=item L<Padre::Wx::Popup>

not in use.

=item L<Padre::Wx::Printout>

Implementing the printing capability of Padre.

=item L<Padre::Wx::SyntaxCheck>

Implementing the continuous syntax check of Perl code.

=item L<Padre::Wx::ToolBar>

handles everything the toolbar should know and do.

=back

=head1 BUGS

Please submit your bugs at L<http://padre.perlide.org/>

=head1 SUPPORT

I hope the L<http://www.perlmonks.org/> will be ready to take
upon themselves supporting this application.

See also L<http://padre.perlide.org/>

=head1 COPYRIGHT

Copyright 2008-2010 The Padre development team as listed in Padre.pm.
L<http://padre.perlide.org/>

=head1 LICENSE

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl 5 itself.

=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.

=head1 ACKNOWLEDGEMENTS

=encoding utf8

=head2 The Padre development team

The developers of Padre in alphabetical order:

Aaron Trevena (TEEJAY)

Ahmad Zawawi أحمد محمد زواوي (AZAWAWI)

Adam Kennedy (ADAMK) E<lt>adamk@cpan.orgE<gt>

Breno G. de Oliveira (GARU)

Brian Cassidy (BRICAS)

Cezary Morga (THEREK) E<lt>cm@therek.netE<gt>

Chris Dolan (CHRISDOLAN)

Claudio Ramirez (CLAUDIO) E<lt>padre.claudio@apt-get.beE<gt>

Fayland Lam (FAYLAND) E<lt>fayland@gmail.comE<gt>

Gabriel Vieira (GABRIELMAD)

Gábor Szabó - גאבור סבו (SZABGAB) E<lt>szabgab@gmail.comE<gt>

Heiko Jansen (HJANSEN) E<lt>heiko_jansen@web.deE<gt>

Jérôme Quelin (JQUELIN) E<lt>jquelin@cpan.orgE<gt>

Kaare Rasmussen (KAARE) E<lt>kaare@cpan.orgE<gt>

Keedi Kim - 김도형 (KEEDI)

Kenichi Ishigaki - 石垣憲一 (ISHIGAKI) E<lt>ishigaki@cpan.orgE<gt>

Max Maischein (CORION)

Patrick Donelan (PDONELAN) E<lt>pat@patspam.comE<gt>

Paweł Murias (PMURIAS)

Petar Shangov (PSHANGOV)

Ryan Niebur (RSN) E<lt>rsn@cpan.orgE<gt>

Sebastian Willing (SEWI)

Steffen Müller (TSEE) E<lt>smueller@cpan.orgE<gt>

Mark Grimes E<lt>mgrimes@cpan.orgE<gt>

=head2 Translators

=head3 Arabic

Ahmad M. Zawawi - أحمد محمد زواوي (AZAWAWI)

=head3 Chinese (Simplified)

Fayland Lam (FAYLAND)

=head3 Chinese (Traditional)

BlueT - Matthew Lien - 練喆明 (BLUET) E<lt>bluet@cpan.orgE<gt>

=head3 Dutch

Dirk De Nijs (ddn123456)

=head3 English

Everyone on the team

=head3 French

Jérôme Quelin (JQUELIN)

=head3 German

Heiko Jansen (HJANSEN)
Sebastian Willing (SEWI)

=head3 Hebrew

Omer Zak  - עומר זק

Shlomi Fish  - שלומי פיש (SHLOMIF)

Amir E. Aharoni - אמיר א. אהרוני

=head3 Hungarian

György Pásztor (GYU)

=head3 Italian

Simone Blandino (SBLANDIN)

=head3 Japanese

Kenichi Ishigaki - 石垣憲一 (ISHIGAKI)

=head3 Korean

Keedi Kim - 김도형 (KEEDI)

=head3 Russian

Andrew Shitov

=head3 Polish

Cezary Morga (THEREK)

=head3 Portuguese (Brazilian)

Breno G. de Oliveira (GARU)

=head3 Spanish

Paco Alguacil (PacoLinux)

Enrique Nell (ENELL)

=head3 Czech

Marcela Mašláňová (mmaslano)

=head3 Norwegian

Kjetil Skotheim (KJETIL)

=head2 Thanks

Mattia Barbon for providing wxPerl.
Part of the code was copied from his Wx::Demo application.

Herbert Breunung for letting me work on Kephra.

Octavian Rasnita for early testing and bug reports.

Tatsuhiko Miyagawa for consulting on our I18N and L10N support.

=cut

# Copyright 2008-2010 The Padre development team as listed in Padre.pm.
# LICENSE
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl 5 itself.
