package Padre::Document;

=pod

=head1 NAME

Padre::Document - Padre Document API

=head1 DESCRIPTION

The B<Padre::Document> class provides a base class, default implementation
and API documentation for document type support in L<Padre>.

As an API, it allows L<Padre> developers and plug-in authors to implement
extended support for various document types in Padre, while ensuring that
a naive default document implementation exists that allows Padre to provide
basic support (syntax highlighting mainly) for many document types without
the need to install extra modules unless you need the extra functionality.

=head2 Document Type Registration

Padre uses MIME types as the fundamental identifier when working with
documents. Files are typed at load-time based on file extension (with a
simple heuristic fallback when opening files with no extension).

Many of the MIME types are unofficial X-style identifiers, but in cases
without an official type, Padre will try to use the most popular
identifier (based on research into the various language communities).

Each supported mime has a mapping to a Scintilla lexer (for syntax
highlighting), and an optional mapping to the class that provides enhanced
support for that document type.

Plug-ins that implement support for a document type provide a
C<registered_documents> method that the plug-in manager will call as needed.

Plug-in authors should B<not> load the document classes in advance, they
will be automatically loaded by Padre as needed.

Padre does B<not> currently support opening non-text files.

=head2 File to MIME type mapping

Padre has a built-in hash mapping the file extensions to MIME types.
In certain cases (.t, .pl, .pm) Padre also looks in the content of the
file to determine if the file is Perl 5 or Perl 6.

MIME types are mapped to lexers that provide the syntax highlighting.

MIME types are also mapped to modules that implement
special features needed by that kind of a file type.

Plug-ins can add further mappings.

=head2 Plan

Padre has a built-in mapping of file extension to either
a single MIME type or function name. In order to determine
the actual MIME type Padre checks this hash. If the key
is a subroutine it is called and it should return the
MIME type of the file.

The user has a way in the GUI to add more file extensions
and map them to existing MIME types or functions. It is probably
better to have a commonly used name along with the MIME type
in that GUI instead of the MIME type only.

I wonder if we should allow the users (and or plug-in authors) to
change the functions or to add new functions that will map
file content to MIME type or if we should just tell them to
patch Padre. What if they need it for some internal project?

A plug-in is able to add new supported MIME types. Padre should
either check for collisions if a plug-in already wants to provide
an already supported MIME type or should allow multiple support
modules with a way to select the current one. (Again I think we
probably don't need this. People can just come and add the
MIME types to Padre core.) (not yet implemented)

A plug-in can register zero or more modules that implement
special features needed by certain MIME types. Every MIME type
can have only one module that implements its features. Padre is
checking if a MIME type already has a registered module and
does not let to replace it.
(Special features such as commenting out a few lines at once,
auto-completion or refactoring tools).

Padre should check if the given MIME type is one that is
in the supported MIME type list. (TO DO)

Each MIME type is mapped to one or more lexers that provide
the syntax highlighting. Every MIME type has to be mapped to at least
one lexer but it can be mapped to several lexers as well.
The user is able to select the lexer for each MIME type.
(For this each lexer should have a reasonable name too.) (TO DO)

Every plug-in should be able to add a list of lexers to the existing
MIME types regardless if the plug-in also provides the class that
implements the features of that MIME type. By default Padre
supports the built-in syntax highlighting of Scintilla.
Perl 5 currently has two L<PPI> based syntax highlighter,
Perl 6 can use the STD.pm or Rakudo/PGE for syntax highlighting but
there are two plug-ins – Parrot and Kate – that can provide syntax
highlighting to a wide range of MIME types.

C<provided_highlighters()> returns a list of arrays like this:

    ['Module with a colorize function' => 'Human readable Name' => 'Long description']

C<highlighting_mime_types()> returns a hash where the keys are module
names listed in C<provided_highlighters>, the values are array references to MIME types:

    'Module::A' => [ mime-type-1, mime-type-2]

The user can change the MIME type mapping of individual
files and Padre should remember this choice and allow the
user to change it to another specific MIME type
or to set it to "Default by extension".

=head1 METHODS

=cut

use 5.008;
use strict;
use warnings;
use Carp             ();
use File::Spec       ();
use File::Temp       ();
use Padre::Constant  ();
use Padre::Current   ();
use Padre::Util      ();
use Padre::Wx        ();
use Padre            ();
use Padre::MimeTypes ();
use Padre::File      ();
use Padre::Logger;

our $VERSION = '0.61';





#####################################################################
# Document Registration

# NOTE: This is probably a bad place to store this
my $unsaved_number = 0;





#####################################################################
# Constructor and Accessors

use Class::XSAccessor {
	getters => {
		filename    => 'filename',   # setter is defined as normal function
		file        => 'file',       # Padre::File - object
		editor      => 'editor',
		timestamp   => 'timestamp',
		mimetype    => 'mimetype',
		errstr      => 'errstr',
		tempfile    => 'tempfile',
		highlighter => 'highlighter',
	},
	setters => {
		set_editor       => 'editor',
		set_timestamp    => 'timestamp',
		set_mimetype     => 'mimetype',
		set_newline_type => 'newline_type',
		set_errstr       => 'errstr',
		set_tempfile     => 'tempfile',
		set_highlighter  => 'highlighter',
	},
};

=pod

=head2 C<new>

  my $doc = Padre::Document->new(
      filename => $file,
  );

C<$file> is optional and if given it will be loaded in the document.
MIME type is defined by the C<guess_mimetype> function.

=cut

sub new {
	my $class = shift;
	my $self = bless {@_}, $class;

	# This sub creates the document object and is allowed to use self->filename,
	# once noone else uses it, it shout be deleted from the $self - hash before
	# leaving the sub.
	# Use document->{file}->filename instead!
	if ( $self->{filename} ) {
		$self->{file} = Padre::File->new(
			$self->{filename},
			info_handler => sub {
				my $self    = shift;
				my $message = shift;
				Padre->ide->wx->main->info($message);
			}
		);

		unless ( defined $self->{file} ) {
			$self->error( Wx::gettext('Error while opening file: no file object') );
			return;
		}

		if ( defined $self->{file}->{error} ) {
			$self->error( $self->{file}->{error} );
			return;
		}

		# The Padre::File - module knows how to format the filename to the right
		# syntax to correct (for example) .//file.pl to ./file.pl)
		$self->{filename} = $self->{file}->{filename};

		# TODO: Fix Ticket #845 here. We need to make sure only the filename and not the folder name is here.
		# This causes F5 to fail as the get_command in Document::Perl doesn' handle this corretly

		if ( $self->{file}->exists ) {

			# Test script must be able to pass an alternate config object:
			my $config = $self->{config} || Padre->ide->config;
			if ( defined( $self->{file}->size ) and ( $self->{file}->size > $config->editor_file_size_limit ) ) {
				$self->error(
					sprintf(
						Wx::gettext(
							"Cannot open %s as it is over the arbitrary file size limit of Padre which is currently %s"
						),
						$self->{file}->{filename},
						$config->editor_file_size_limit
					)
				);
				return;
			}
		}
		$self->load_file;
	} else {
		$unsaved_number++;
		$self->{newline_type} = $self->default_newline_type;
	}

	unless ( $self->mimetype ) {
		my $mimetype = $self->guess_mimetype;
		if ( defined $mimetype ) {
			$self->set_mimetype($mimetype);
		} else {
			$self->error(
				Wx::gettext(
					"Error while determining MIME type.\nThis is possibly an encoding problem.\nAre you trying to load a binary file?"
				)
			);
			return;
		}
	}

	$self->rebless;

	Padre->ide->{_popularity_contest}->count( 'mime.' . $self->mimetype )
		if ( !defined( $ENV{PADRE_IS_TEST} ) )
		and defined( Padre->ide->{_popularity_contest} );

	return $self;
}

sub rebless {
	my ($self) = @_;

	# Rebless as either to a subclass if there is a mime-type or
	# to the the base class,
	# This isn't exactly the most elegant way to do this, but will
	# do for a first implementation.
	my $mime_type = $self->mimetype or return;
	my $class = Padre::MimeTypes->get_mime_class($mime_type) || __PACKAGE__;
	TRACE("Reblessing to mimetype: '$class'") if DEBUG;
	if ($class) {
		unless ( $class->VERSION ) {
			eval "require $class;";
			die("Failed to load $class: $@") if $@;
		}
		bless $self, $class;
	}

	my $module   = Padre::MimeTypes->get_current_highlighter_of_mime_type($mime_type);
	my $filename = '';                                                                # Not undef
	$filename = $self->{file}->filename
		if defined( $self->{file} )
			and defined( $self->{file}->{filename} );
	warn("No module  mime_type='$mime_type' filename='$filename'\n") unless $module;

	#warn("Module '$module' mime_type='$mime_type' filename='$filename'\n") if $module;
	$self->set_highlighter($module);

	return;
}

sub current {
	Padre::Current->new( document => $_[0] );
}





#####################################################################
# Padre::Document GUI Integration

sub colourize {
	my $self   = shift;
	my $lexer  = $self->lexer;
	my $editor = $self->editor;
	$editor->SetLexer($lexer);

	$self->remove_color;
	if ( $lexer == Wx::wxSTC_LEX_CONTAINER ) {
		$self->colorize;
	} else {
		$editor->Colourise( 0, $editor->GetLength );
	}
}

sub colorize {
	my $self = shift;
	TRACE("colorize called") if DEBUG;

	my $module = $self->highlighter;
	TRACE("module: '$module'") if DEBUG;
	if ( $module eq 'stc' ) {

		#TO DO sometime this happens when I open Padre with several file
		# I think this can be somehow related to the quick (or slow ?) switching of
		# what is the current document while the code is still running.
		# for now I hide the warnings as this would just frighten people and the
		# actual problem seems to be only the warning or maybe late highighting
		# of a single document - szabgab
		#Carp::cluck("highlighter is set to 'stc' while colorize() is called for " . ($self->filename || '') . "\n");
		#warn "Length: " . $self->editor->GetTextLength;
		return;
	}

	# allow virtual modules if they have a colorize method
	unless ( $module->can('colorize') ) {
		eval "use $module";
		if ($@) {
			Carp::cluck( "Could not load module '$module' for file '" . ( $self->{file}->filename || '' ) . "'\n" );
			return;
		}
	}
	if ( $module->can('colorize') ) {
		TRACE("Call '$module->colorize(@_)'") if DEBUG;
		$module->colorize(@_);
	} else {
		warn("Module $module does not have a colorize method\n");
	}
	return;
}

sub timestamp_now {
	my $self = shift;
	my $file = $self->file;
	return 0 unless defined $file;

	# It's important to return undef if there is no ->mtime for this filetype
	return unless $file->can('mtime');
	return $file->mtime;
}

# For ts without a newline type
# TO DO: get it from config
sub default_newline_type {
	my $self = shift;

	# Very ugly hack to make the test script work
	if ( $0 =~ /t.70\-document\.t/ ) {
		return Padre::Constant::NEWLINE;
	}

	$self->current->config->default_line_ending;
}

=pod

=head2 C<error>

    $document->error( $msg );

Open an error dialog box with C<$msg> as main text. There's only one OK
button. No return value.

=cut

# TO DO: A globally used error/message box function may be better instead
#       of replicating the same function in many files:
sub error {
	Padre->ide->wx->main->message( $_[1], Wx::gettext('Error') );
}





#####################################################################
# Disk Interaction Methods
# These methods implement the interaction between the document and the
# filesystem.

sub basename {
	my $self = shift;
	if ( defined $self->{file} ) {
		return $self->{file}->basename;
	}
	return $self->{file}->{filename};
}

sub dirname {
	my $self = shift;
	if ( defined $self->{file} ) {
		return $self->{file}->dirname;
	}
	return;
}

sub is_new {
	return !!( not defined $_[0]->file );
}

sub is_modified {
	return !!( $_[0]->editor->GetModify );
}

sub is_saved {
	return !!( defined $_[0]->file and not $_[0]->is_modified );
}

# Returns true if this is a new document that is too insignificant to
# bother checking with the user before throwing it away.
# Usually this is because it's empty or just has a space or two in it.
sub is_unused {
	my $self = shift;
	return '' unless $self->is_new;
	return 1  unless $self->is_modified;
	return 1  unless $self->text_get =~ /\S/s;
	return '';
}

# Returns true if file has changed on the disk
# since load time or the last time we saved it.
# Check if the file on the disk has changed
# 1) when document gets the focus (gvim, notepad++)
# 2) when we try to save the file (gvim)
# 3) every time we type something ????
sub has_changed_on_disk {
	my ($self) = @_;
	return 0 unless defined $self->file;
	return 0 unless defined $self->timestamp;

	# Caching the result for two lines saved one stat-I/O each time this sub is run
	my $timestamp_now = $self->timestamp_now;
	return 0 unless defined $timestamp_now; # there may be no mtime on remote files

	# Return -1 if file has been deleted from disk
	return -1 unless $timestamp_now;

	# Return 1 if the file has changed on disk, otherwise 0
	return $self->timestamp < $timestamp_now ? 1 : 0;
}

# Generate MD5-checksum for current file stored on disk
sub checksum_on_file {
	warn join( ',', caller ) . ' called Document::checksum_on_file which is out-of-service.';
	return 1;
}

# Part of the above checksum_on_file sub
# Commented out to keep Perl::Critic happy
#my $self = shift;
#
#my $filename = $self->{file}->filename;
#return unless defined $filename;
#
#require Digest::MD5;
#
#open my $FH, '<', $filename or return;
#binmode($FH);
#return Digest::MD5->new->addfile(*$FH)->hexdigest;

=pod

=head2 C<load_file>

 $doc->load_file;

Loads the current file.

Sets the B<Encoding> bit using L<Encode::Guess> and tries to figure
out what kind of newlines are in the file. Defaults to C<utf-8> if it
could not figure out the encoding.

Returns true on success false on failure. Sets C<< $doc->errstr >>.

=cut

sub load_file {
	my ($self) = @_;
	my $file = $self->file;

	if (DEBUG) {
		my $name = $file->{file}->{filename} || '';
		TRACE("Loading file '$name'");
	}

	# check if file exists
	if ( !$file->exists ) {

		# file doesn't exist, try to create an empty one
		if ( !$file->write('') ) {

			# oops, error creating file. abort operation
			$self->set_errstr( $file->error );
			return;
		}
	}

	# load file
	$self->set_errstr('');
	my $content = $file->read;
	if ( !defined($content) ) {
		$self->set_errstr( $file->error );
		return;
	}
	$self->{timestamp} = $self->timestamp_now;

	# if guess encoding fails then use 'utf-8'
	require Padre::Locale;
	$self->{encoding} = Padre::Locale::encoding_from_string($content);

	#warn $self->{encoding};
	$content = Encode::decode( $self->{encoding}, $content );

	$self->{original_content} = $content;

	# Determine new line type using file content.
	$self->{newline_type} = Padre::Util::newline_type($content);

	return 1;
}

# New line type can be one of these values:
# WIN, MAC (for classic Mac) or UNIX (for Mac OS X and Linux/*BSD)
# Special cases:
# 'Mixed' for mixed end of lines,
# 'None' for one-liners (no EOL)
sub newline_type {
	$_[0]->{newline_type} or $_[0]->default_newline_type;
}

# Get the newline char(s) for this document.
# TO DO: This solution is really terrible - it should be {newline} or at least a caching of the value
#       because of speed issues:
sub newline {
	my $self = shift;
	if ( $self->newline_type eq 'WIN' ) {
		return "\r\n";
	} elsif ( $self->newline_type eq 'MAC' ) {
		return "\r";
	}
	return "\n";
}

=pod

=head2 C<autocomplete_matching_char>

The first argument needs to be a reference to the editor this method should
work on.

The second argument is expected to be a event reference to the event object
which is the reason why the method was launched.

This method expects a hash as the third argument. If the last key typed by the
user is a key in this hash, the value is automatically added and the cursor is
set between key and value. Both key and value are expected to be ASCII codes.

Usually used for brackets and text signs like:

  $self->autocomplete_matching_char(
      $editor,
      $event,
      39  => 39,  # ' '
      40  => 41,  # ( )
  );

Returns 1 if something was added or 0 otherwise (if anybody cares about this).

=cut

sub autocomplete_matching_char {
	my $self   = shift;
	my $editor = shift;
	my $event  = shift;
	my %table  = @_;

	my $config = Padre->ide->config;
	my $main   = Padre->ide->wx->main;

	my $selection_exists = 0;
	my $text             = $editor->GetSelectedText;
	if ( defined($text) && length($text) > 0 ) {
		$selection_exists = 1;
	}

	my $key = $event->GetUnicodeKey;

	my $pos   = $editor->GetCurrentPos;
	my $line  = $editor->LineFromPosition($pos);
	my $first = $editor->PositionFromLine($line);
	my $last  = $editor->PositionFromLine( $line + 1 ) - 1;

	if ( $config->autocomplete_brackets ) {
		if ( $table{$key} ) {
			if ($selection_exists) {
				my $start = $editor->GetSelectionStart;
				my $end   = $editor->GetSelectionEnd;
				$editor->GotoPos($end);
				$editor->AddText( chr( $table{$key} ) );
				$editor->GotoPos($start);
			} else {
				my $nextChar;
				if ( $editor->GetTextLength > $pos ) {
					$nextChar = $editor->GetTextRange( $pos, $pos + 1 );
				}
				unless ( defined($nextChar) && ord($nextChar) == $table{$key}
					and ( !$config->autocomplete_multiclosebracket ) )
				{
					$editor->AddText( chr( $table{$key} ) );
					$editor->CharLeft;
				}
			}
			return 1;
		}
	}

	return 0;

}

sub set_filename {
	my $self     = shift;
	my $filename = shift;

	unless ( defined $filename ) {
		warn 'Request to set filename to undef from ' . join( ',', caller );
		return 0;
	}

	# Shortcut if no change in file name
	if ( defined $self->{filename} and $self->{filename} eq $filename ) {
		return 1;
	}

	# Flush out old state information, primarily the file object.
	# Additionally, whenever we change the name of the file we can no
	# longer trust that we are in the same project, so flush that as well.
	delete $self->{filename};
	delete $self->{file};
	delete $self->{project_dir};
	delete $self->{is_project};

	# Save the new filename
	$self->{file} = Padre::File->new($filename);

	# Padre::File reformats filenames to the protocol/OS specific format, so use this:
	$self->{filename} = $self->{file}->{filename};
}

# Only a dummy for documents which don't support this
sub autoclean {
	my $self = shift;

	return 1;
}

sub save_file {
	my $self = shift;

	# If padre is run on files that have no project
	# I.E Padre foo.pl &
	# The assumption of $self->project as defined will cause a fail
	# Please be more careful mkkkay!
	my $config;
	$config = $self->project->config if $self->project;
	$self->set_errstr('');

	$self->autoclean if $config && $config->save_autoclean;

	my $content = $self->text_get;
	my $file    = $self->file;
	unless ( defined $file ) {

		# NOTE: Now we have ->set_filename, should this situation ever occur?
		$file = Padre::File->new( $self->filename );
		$self->{file} = $file;
	}

	# This is just temporary for security and should prevend data loss:
	if ( $self->{filename} ne $file->{filename} ) {
		my $ret = Wx::MessageBox(
			sprintf(
				Wx::gettext('Visual filename %s does not match the internal filename %s, do you want to abort saving?'),
				$self->{filename},
				$file->{filename}
			),
			Wx::gettext("Save Warning"),
			Wx::wxYES_NO | Wx::wxCENTRE,
			Padre->ide->wx->main,
		);

		return 0 if $ret == Wx::wxYES;
	}

	# Not set when first time to save
	# Allow the upgrade from ascii to utf-8 if there were unicode characters added
	unless ( $self->{encoding} and $self->{encoding} ne 'ascii' ) {
		require Padre::Locale;
		$self->{encoding} = Padre::Locale::encoding_from_string($content);
	}

	my $encode = '';
	if ( defined $self->{encoding} ) {
		$encode = ":raw:encoding($self->{encoding})";
	} else {
		warn "encoding is not set, (couldn't get from contents) when saving file $file->{filename}\n";
	}

	unless ( $file->write( $content, $encode ) ) {
		$self->set_errstr( $file->error );
		return;
	}

	# File must be closed at this time, slow fs/userspace-fs may not
	# return the correct result otherwise!
	$self->{timestamp} = $self->timestamp_now;

	# Determine new line type using file content.
	$self->{newline_type} = Padre::Util::newline_type($content);

	# Update read-only-cache
	$self->{readonly} = $self->file->readonly;

	return 1;
}

=pod

=head2 C<write>

Writes the document to an arbitrary local file using the same semantics
as when we do a full file save.

=cut

sub write {
	my $self = shift;
	my $file = shift;          # File object, not just path
	my $text = $self->text_get;

	# Get the locale, but don't save it.
	# This could fire when only one of two characters have been
	# typed, and we may not know the encoding yet.
	# Not set when first time to save
	# Allow the upgrade from ascii to utf-8 if there were unicode characters added
	my $encoding = $self->{encoding};
	unless ( $encoding and $encoding ne 'ascii' ) {
		require Padre::Locale;
		$encoding = Padre::Locale::encoding_from_string($text);
	}
	if ( defined $encoding ) {
		$encoding = ":raw:encoding($encoding)";
	}

	# Write the file
	$file->write( $text, $encoding );
}

=pod

=head2 C<reload>

Reload the current file discarding changes in the editor.

Returns true on success false on failure. Error message will be in C<< $doc->errstr >>.

TO DO: In the future it should backup the changes in case the user regrets the action.

=cut

sub reload {
	my ($self) = @_;

	my $file = $self->file or return;
	return $self->load_file;
}

# Copies document content to a temporary file.
# Returns temporary file name.
sub store_in_tempfile {
	my $self = shift;

	$self->create_tempfile unless $self->tempfile;

	open my $FH, ">", $self->tempfile;
	print $FH $self->text_get;
	close $FH;

	return $self->tempfile;
}

sub create_tempfile {
	my $tempfile = File::Temp->new( UNLINK => 0 );
	$_[0]->set_tempfile( $tempfile->filename );
	close $tempfile;

	return;
}

sub remove_tempfile {
	unlink $_[0]->tempfile;
	return;
}





#####################################################################
# Basic Content Manipulation

sub text_get {
	$_[0]->editor->GetText;
}

sub text_set {
	$_[0]->editor->SetText( $_[1] );
}

sub text_like {
	my $self = shift;
	return !!( $self->text_get =~ /$_[0]/m );
}

sub text_with_one_nl {
	my $self   = shift;
	my $text   = $self->text_get;
	my $nlchar = "\n";
	if ( $self->newline_type eq 'WIN' ) {
		$nlchar = "\r\n";
	} elsif ( $self->newline_type eq 'MAC' ) {
		$nlchar = "\r";
	}
	$text =~ s/$nlchar/\n/g;
	return $text;
}

#
# $doc->store_cursor_position()
#
# store document's current cursor position in padre's db.
# no params, no return value.
#
sub store_cursor_position {
	my $self     = shift;
	my $filename = defined( $self->{file} ) ? $self->{file}->filename : undef;
	my $editor   = $self->editor;
	return unless $filename && $editor;
	my $pos = $editor->GetCurrentPos;
	Padre::DB::LastPositionInFile->set_last_pos( $filename, $pos );
}

#
# $doc->restore_cursor_position()
#
# restore document's cursor position from padre's db.
# no params, no return value.
#
sub restore_cursor_position {
	my $self     = shift;
	my $filename = defined( $self->{file} ) ? $self->{file}->filename : undef;
	my $editor   = $self->editor;
	return unless $filename && $editor;
	my $pos = Padre::DB::LastPositionInFile->get_last_pos($filename);
	return unless $pos;
	$editor->SetCurrentPos($pos);
	$editor->SetSelection( $pos, $pos );
}





#####################################################################
# GUI Integration Methods

# Determine the Scintilla lexer to use
sub lexer {
	my $self = shift;

	# this should never happen as now we set mime-type on everything
	return Wx::wxSTC_LEX_AUTOMATIC unless $self->mimetype;

	my $highlighter = $self->highlighter;
	if ( not $highlighter ) {
		warn "no highlighter\n";
		$highlighter = 'stc';
	}
	return Wx::wxSTC_LEX_CONTAINER if $highlighter ne 'stc';
	return Wx::wxSTC_LEX_AUTOMATIC unless defined Padre::MimeTypes->get_lexer( $self->mimetype );

	TRACE( 'STC Lexer will be based on mime type "' . $self->mimetype . '"' ) if DEBUG;
	return Padre::MimeTypes->get_lexer( $self->mimetype );
}

# What should be shown in the notebook tab
sub get_title {
	my $self = shift;
	if ( defined( $self->{file} ) and defined( $self->{file}->filename ) and ( $self->{file}->filename ne '' ) ) {
		return $self->basename;
	} else {
		my $str = sprintf( Wx::gettext("Unsaved %d"), $unsaved_number );

		# A bug in Wx requires a space at the front of the title
		# (For reasons I don't understand yet)
		return ' ' . $str;
	}
}

sub remove_color {
	my ($self) = @_;

	TRACE("remove_color called (@_)") if DEBUG;

	my $editor = $self->editor;

	TRACE("editor '$editor'") if DEBUG;

	# TO DO this is strange, do we really need to do it with all?
	foreach my $i ( 0 .. 31 ) {
		$editor->StartStyling( 0, $i );
		$editor->SetStyling( $editor->GetLength, 0 );
	}

	return;
}

# TO DO: experimental
sub get_indentation_style {
	my $self   = shift;
	my $config = Padre->ide->config;

	# TO DO: (document >) project > config

	my $style;
	if ( $config->editor_indent_auto ) {

		# TO DO: This should be cached? What's with newish documents then?
		$style = $self->guess_indentation_style;
	} else {
		$style = {
			use_tabs    => $config->editor_indent_tab,
			tabwidth    => $config->editor_indent_tab_width,
			indentwidth => $config->editor_indent_width,
		};
	}

	return $style;
}

=head2 C<set_indentation_style>

Given a hash reference with the keys C<use_tabs>,
C<tabwidth>, and C<indentwidth>, set the document's editor's
indentation style.

Without an argument, falls back to what C<get_indentation_style>
returns.

=cut

sub set_indentation_style {
	my $self   = shift;
	my $style  = shift || $self->get_indentation_style;
	my $editor = $self->editor;

	# The display width of literal tab characters (ne "indentation width"!)
	$editor->SetTabWidth( $style->{tabwidth} );

	# The actual indentation width in COLUMNS!
	$editor->SetIndent( $style->{indentwidth} );

	# Use tabs for indentation where possible?
	$editor->SetUseTabs( $style->{use_tabs} );

	return ();
}

=head2 C<get_indentation_level_string>

Calculates the string that should be used to indent a given
number of levels for this document.

Takes the indentation level as an integer argument which
defaults to one. Note that indenting to level 2 may be different
from just concatenating the indentation string to level one twice
due to tab compression.

=cut

sub get_indentation_level_string {
	my $self  = shift;
	my $level = shift;
	$level = 1 if not defined $level;
	my $style        = $self->get_indentation_style;
	my $indent_width = $style->{indentwidth};
	my $tab_width    = $style->{tabwidth};
	my $indent;

	if ( $style->{use_tabs} and $indent_width != $tab_width ) {

		# do tab compression if necessary
		# - First, convert all to spaces (aka columns)
		# - Then, add an indentation level
		# - Then, convert to tabs as necessary
		my $tab_equivalent = " " x $tab_width;
		$indent = ( " " x $indent_width ) x $level;
		$indent =~ s/$tab_equivalent/\t/g;
	} elsif ( $style->{use_tabs} ) {
		$indent = "\t" x $level;
	} else {
		$indent = ( " " x $indent_width ) x $level;
	}
	return $indent;
}

=head2 C<event_on_char>

NOT IMPLEMENTED IN THE BASE CLASS

This method - if implemented - is called after any addition of a character
to the current document. This enables document classes to aid the user
in the editing process in various ways, e.g. by auto-pairing of brackets
or by suggesting usable method names when method-call syntax is detected.

Parameters retrieved are the objects for the document, the editor, and the
wxWidgets event.

Returns nothing.

Cf. C<Padre::Document::Perl> for an example.

=head2 C<event_on_right_down>

NOT IMPLEMENTED IN THE BASE CLASS

This method - if implemented - is called when a user right-clicks in an
editor to open a context menu and after the standard context menu was
created and populated in the C<Padre::Wx::Editor> class.
By manipulating the menu document classes may provide the user with
additional options.

Parameters retrieved are the objects for the document, the editor, the
context menu (C<Wx::Menu>) and the event.

Returns nothing.

=head2 C<event_on_left_up>

NOT IMPLEMENTED IN THE BASE CLASS

This method - if implemented - is called when a user left-clicks in an
editor. This can be used to implement context-sensitive actions if
the user presses modifier keys while clicking.

Parameters retrieved are the objects for the document, the editor,
and the event.

Returns nothing.

=cut





#####################################################################
# Project Integration Methods

sub project {
	my $self = shift;
	my $root = $self->project_dir;
	if ( defined $root ) {
		return Padre->ide->project($root);
	} else {
		return;
	}
}

sub project_dir {
	my $self = shift;
	unless ( $self->{project_dir} ) {

		# Load the project object and project_dir in one step
		my $project = $self->project_find;
		return unless defined($project);
		my $project_dir = $project->root;
		my $ide         = $self->current->ide;
		$self->{project_dir} = $project_dir;
		$ide->{project}->{$project_dir} = $project;
		unless ( $project->isa('Padre::Project::Null') ) {
			$self->{is_project} = 1;
		}
	}
	return $self->{project_dir};
}

sub project_find {
	my $self = shift;

	# Anonymous files don't have a project
	return unless defined $self->file;

	# Currently no project support for remote files
	return unless $self->{file}->{protocol} eq 'local';

	# Search upwards from the file to find the project root
	require Padre::Project;
	Padre::Project->from_file( $self->{file}->{filename} );
}

# Find the project-relative file name
sub filename_relative {
	File::Spec->abs2rel( $_[0]->filename, $_[0]->project_dir );
}





#####################################################################
# Document Analysis Methods

# Unreliable methods that provide heuristic best-attempts at automatically
# determining various document properties.

# Left here as it is used in many places.
# Maybe we need to remove this sub.
sub guess_mimetype {
	my $self = shift;
	Padre::MimeTypes->guess_mimetype(
		$self->{original_content},
		$self->file,
	);
}

=head2 C<guess_indentation_style>

Automatically infer the indentation style of the document using
L<Text::FindIndent>.

Returns a hash reference containing the keys C<use_tabs>,
C<tabwidth>, and C<indentwidth>. It is suitable for passing
to C<set_indendentation_style>.

=cut

sub guess_indentation_style {
	my $self = shift;

	require Text::FindIndent;
	my $indentation = Text::FindIndent->parse(
		$self->text_get,
		skip_pod => $self->isa('Padre::Document::Perl'),
	);

	my $style;
	if ( $indentation =~ /^t\d+/ ) { # we only do ONE tab
		$style = {
			use_tabs    => 1,
			tabwidth    => 8,
			indentwidth => 8,
		};
	} elsif ( $indentation =~ /^s(\d+)/ ) {
		$style = {
			use_tabs    => 0,
			tabwidth    => 8,
			indentwidth => $1,
		};
	} elsif ( $indentation =~ /^m(\d+)/ ) {
		$style = {
			use_tabs    => 1,
			tabwidth    => 8,
			indentwidth => $1,
		};
	} else {

		# fallback
		my $config = Padre->ide->config;
		$style = {
			use_tabs    => $config->editor_indent_tab,
			tabwidth    => $config->editor_indent_tab_width,
			indentwidth => $config->editor_indent_width,
		};
	}

	return $style;
}

=head2 C<guess_filename>

  my $name = $document->guess_filename

When creating new code, one job that the editor should really be able to do
for you without needing to be told is to work out where to save the file.

When called on a new unsaved file, this method attempts to guess what the
name of the file should be based purely on the content of the file.

In the base implementation, this returns C<undef> to indicate that the
method cannot make a reasonable guess at the name of the file.

Your MIME type specific document subclass should implement any file name
detection as it sees fit, returning the file name as a string.

=cut

sub guess_filename {
	my $self = shift;

	# If the file already has an existing name, guess that
	my $filename = $self->filename;
	if ( defined $filename ) {
		return ( File::Spec->splitpath($filename) )[2];
	}

	return undef;
}

=head2 C<guess_subpath>

  my $subpath = $document->guess_subpath;

When called on a new unsaved file, this method attempts to guess what the
sub-path of the file should be inside of the current project, based purely
on the content of the file.

In the base implementation, this returns a null list to indicate that the
method cannot make a reasonable guess at the name of the file.

Your MIME type specific document subclass should implement any file name
detection as it sees fit, returning the project-rooted sub-path as a list
of directory names.

These directory names do not need to exist, they only represent intent.

=cut

sub guess_subpath {
	my $self = shift;

	# For an unknown document type, we cannot make any reasonable guess
	return ();
}

# Abstract methods, each subclass should implement it
# TO DO: Clearly this isn't ACTUALLY abstract (since they exist)

sub keywords {
	return {};
}

sub get_functions {
	return ();
}

sub get_function_regex {
	return '';
}

sub pre_process {
	return 1;
}

sub is_readonly {
	my $self = shift;

	my $file = $self->file;
	return 0 unless defined($file);

	# Fill the cache if it's empty and assume read-write as a default
	$self->{readonly} ||= $self->file->readonly || 0;

	return $self->{readonly};
}

sub selection_stats {
	my ($self) = @_;

	my $text = $self->editor->GetSelectedText;

	my $words   = 0;
	my $newline = $self->newline;
	my $lines   = 1;
	$lines++ while ( $text =~ /$newline/g );
	$words++ while ( $text =~ /\s+/g );

	my $chars_with_space    = length $text;
	my $whitespace          = "\n\r\t ";
	my $chars_without_space = $chars_with_space - ( $text =~ tr/$whitespace// );

	return ( $lines, $chars_with_space, $chars_without_space, $words );
}

sub stats {
	my ($self) = @_;

	my ( $chars_without_space, $words ) = (0) x 2;

	my $editor = $self->editor;
	my $text   = $self->text_get;

	my $lines            = $editor->GetLineCount();
	my $chars_with_space = $editor->GetTextLength();

	# TODO: Remove this limit? Right now, it is greater than the default file size limit.
	if ( length $text < 2_500_000 ) {
		$words++ while ( $text =~ /\s+/g );

		my $whitespace = "\n\r\t ";

		# TODO: make this depend on the current character set
		#       see http://en.wikipedia.org/wiki/Whitespace_character
		$chars_without_space = $chars_with_space - ( $text =~ tr/$whitespace// );
	} else {
		$words               = Wx::gettext('Skipped for large files');
		$chars_without_space = Wx::gettext('Skipped for large files');
	}

	# not set when first time to save
	# allow the upgread of ascii to utf-8
	require Padre::Locale;
	if ( not $self->{encoding} or $self->{encoding} eq 'ascii' ) {
		$self->{encoding} = Padre::Locale::encoding_from_string($text);
	}
	return (
		$lines, $chars_with_space, $chars_without_space, $words, $self->{newline_type},
		$self->{encoding}
	);
}

=pod

=head2 C<check_syntax>

NOT IMPLEMENTED IN THE BASE CLASS

See also: C<check_syntax_in_background>!

By default, this method will only check the syntax if
the document has changed since the last check. Specify
the C<force =E<gt> 1> parameter to override this.

An implementation in a derived class needs to return an array reference of
syntax problems.

Each entry in the array has to be an anonymous hash with the
following keys:

=over 4

=item * C<line>

The line where the problem resides

=item * C<msg>

A short description of the problem

=item * C<severity>

A flag indicating the problem class: Either 'B<W>' (warning) or 'B<E>' (error)

=item * C<desc>

A longer description with more information on the error (currently
not used but intended to be)

=back

Returns an empty array reference if no problems can be found.

Returns C<undef> if nothing has changed since the last invocation.

Must return the problem list even if nothing has changed when a
parameter is present which evaluates to B<true>.

=head2 C<check_syntax_in_background>

NOT IMPLEMENTED IN THE BASE CLASS

Checking the syntax of documents can take a long time.
Therefore, this method essentially works the same as
C<check_syntax>, but works its magic in a background task
instead. That means it cannot return the syntax-check
structure but instead optionally calls a callback
you pass in as the C<on_finish> parameter.

If you don't specify that parameter, the default
syntax-check-pane updating code will be run after finishing
the check. If you do specify a callback, the first parameter
will be the task object. You can
run the default updating code by executing the
C<update_gui()> method of the task object.

By default, this method will only check the syntax if
the document has changed since the last check. Specify
the C<force =E<gt> 1> parameter to override this.

=cut





#####################################################################
# Document Manipulation Methods

#
# $doc->comment_lines_str;
#
# this is of course dependant on the language, and thus it's actually
# done in the subclasses. however, we provide base empty methods in
# order for padre not to crash if user wants to un/comment lines with
# a document type that did not define those methods.
#
# TO DO Remove this base method, and compensate by disabling the menu entries
# if the document class does not define this method.
sub comment_lines_str { }





#####################################################################
# Unknown Methods
# Dumped here because it's not clear which section they belong in

# should return ($length, @words)
# where $length is the length of the prefix to be replaced by one of the words
# or
# return ($error_message)
# in case of some error
sub autocomplete {
	my $self   = shift;
	my $editor = $self->editor;
	my $pos    = $editor->GetCurrentPos;
	my $line   = $editor->LineFromPosition($pos);
	my $first  = $editor->PositionFromLine($line);

	# line from beginning to current position
	my $prefix = $editor->GetTextRange( $first, $pos );
	$prefix =~ s{^.*?(\w+)$}{$1};
	my $last = $editor->GetLength();
	my $text = $editor->GetTextRange( 0, $last );
	my $pre  = $editor->GetTextRange( 0, $first + length($prefix) );
	my $post = $editor->GetTextRange( $first, $last );

	my $regex = eval {qr{\b(\Q$prefix\E\w+)\b}};
	return ("Cannot build regex for '$prefix'") if $@;

	my %seen;
	my @words;
	push @words, grep { !$seen{$_}++ } reverse( $pre =~ /$regex/g );
	push @words, grep { !$seen{$_}++ } ( $post =~ /$regex/g );

	if ( @words > 20 ) {
		@words = @words[ 0 .. 19 ];
	}

	return ( length($prefix), @words );
}

# Individual document classes should override this method.
# It gets a string (the current selection) and it should
# return a list of files that are possible matches to that file.
# In Perl for example A::B  would be mapped to A/B.pm in various places on
# the filesystem.
sub guess_filename_to_open {
	return;
}

# Individual document classes should override this method.
# It needs to return the document specific help topic string.
# In Perl this is using PPI to find the correct token
sub find_help_topic {
	return;
}

# Individual document classes should override this method.
# see L<Padre::Help>
sub get_help_provider {
	return;
}

1;

# Copyright 2008-2010 The Padre development team as listed in Padre.pm.
# LICENSE
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl 5 itself.
