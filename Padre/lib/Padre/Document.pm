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
either check for collisions if a plug-in wants to provide
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
use Carp ();
use File::Spec 3.21 (); # 3.21 needed for volume-safe abs2rel
use File::Temp       ();
use Params::Util     ();
use Padre::Constant  ();
use Padre::Current   ();
use Padre::Util      ();
use Padre::Wx        ();
use Padre::MimeTypes ();
use Padre::File      ();
use Padre::Logger;

our $VERSION    = '0.91';
our $COMPATIBLE = '0.91';





######################################################################
# Basic Language Support

my %COMMENT_LINE_STRING = (
	'text/x-adasrc'             => '--',
	'text/x-asm'                => '#',
	'application/x-bibtex'      => '%',
	'text/x-c'                  => '//',
	'text/x-c++src'             => '//',
	'text/x-eiffel'             => '--',
	'application/javascript'    => '//',
	'application/x-latex'       => '%',
	'application/x-shellscript' => '#',
	'text/x-java-source'        => '//',
	'text/x-lua'                => '--',
	'text/x-makefile'           => '#',
	'text/x-matlab'             => '%',
	'application/x-perl'        => '#',
	'text/x-python'             => '#',
	'application/x-php'         => '#',
	'application/x-ruby'        => '#',
	'text/x-sql'                => '--',
	'text/x-config'             => '#',
	'text/x-yaml'               => '#',
	'application/x-perl6'       => '#',
	'text/x-csharp'             => '//',
	'text/x-pod'                => '#',
	'text/x-perlxs'             => '//',
);

# Take mostly from src/scite/src/ properties files
my %SCINTILLA_KEY_WORDS = (

	# C/C++ keyword list is obtained from src/scite/src/cpp.properties
	'text/x-c' => [
		[   qw{
				and and_eq asm auto bitand bitor bool break
				case catch char class compl const const_cast continue
				default delete do double dynamic_cast else enum explicit export
				extern false float for friend goto if inline int long mutable
				namespace new not not_eq operator or or_eq private protected
				public register reinterpret_cast return short signed sizeof
				static static_cast struct switch template this throw true try
				typedef typeid typename union unsigned using virtual void
				volatile wchar_t while xor xor_eq
				}
		]
	],

	# Java keyword list is obtained from src/scite/src/cpp.properties
	'text/x-java-source' => [
		[   qw{
				abstract assert boolean break byte case catch char class
				const continue default do double else enum extends final
				finally float for goto if implements import instanceof int
				interface long native new package private protected public
				return short static strictfp super switch synchronized this
				throw throws transient try var void volatile while
				}
		]
	],

	# PHP keyword list is obtained from src/scite/src/html.properties
	'application/x-php' => [
		[   qw{
				and array as bool boolean break case cfunction class const
				continue declare default die directory do double echo else
				elseif empty enddeclare endfor endforeach endif endswitch
				endwhile eval exit extends false float for foreach function
				global goto if include include_once int integer isset list
				namespace new null object old_function or parent print real
				require require_once resource return static stdclass string
				switch true unset use var while xor abstract catch clone
				exception final implements interface php_user_filter private
				protected public this throw try __class__ __dir__ __file__
				__function__ __line__ __method__ __namespace__ __sleep __wakeup
				}
		]
	],

	# SQL keyword list is obtained from src/scite/src/sql.properties
	'text/x-sql' => [
		[   qw{
				absolute action add admin after aggregate alias all allocate
				alter and any are array as asc assertion at authorization
				before begin binary bit blob body boolean both breadth by call
				cascade cascaded case cast catalog char character check class
				clob close collate collation column commit completion connect
				connection constraint constraints constructor continue
				corresponding create cross cube current current_date
				current_path current_role current_time current_timestamp
				current_user cursor cycle data date day deallocate dec decimal
				declare default deferrable deferred delete depth deref desc
				describe descriptor destroy destructor deterministic dictionary
				diagnostics disconnect distinct domain double drop dynamic each
				else end end-exec equals escape every except exception exec
				execute exists exit external false fetch first float for
				foreign found from free full function general get global go
				goto grant group grouping having host hour identity if ignore
				immediate in indicator initialize initially inner inout input
				insert int integer intersect interval into is isolation iterate
				join key language large last lateral leading left less level
				like limit local localtime localtimestamp locator map match
				minute modifies modify module month names national natural
				nchar nclob new next no none not null numeric object of off old
				on only open operation option or order ordinality out outer
				output package pad parameter parameters partial path postfix
				precision prefix preorder prepare preserve primary prior
				privileges procedure public read reads real recursive ref
				references referencing relative restrict result return returns
				revoke right role rollback rollup routine row rows savepoint
				schema scroll scope search second section select sequence
				session session_user set sets size smallint some| space
				specific specifictype sql sqlexception sqlstate sqlwarning
				start state statement static structure system_user table
				temporary terminate than then time timestamp timezone_hour
				timezone_minute to trailing transaction translation treat
				trigger true under union unique unknown unnest update usage
				user using value values varchar variable varying view when
				whenever where with without work write year zone
				}
		]
	],

	# C# keyword list is obtained from src/scite/src/cpp.properties
	'text/x-csharp' => [
		[   qw{
				abstract as ascending base bool break by byte case catch char
				checked class const continue decimal default delegate
				descending do double else enum equals event explicit extern
				false finally fixed float for foreach from goto group if
				implicit in int interface internal into is join lock let long
				namespace new null object on operator orderby out override
				params private protected public readonly ref return sbyte
				sealed select short sizeof stackalloc static string struct
				switch this throw true try typeof uint ulong unchecked unsafe
				ushort using var virtual void where while
				}
		]
	],

	# YAML keyword list is obtained from src/scite/src/yaml.properties
	'text/x-yaml' => [
		[   qw{
				true false yes no
				}
		]
	],

	# The list is obtained from src/scite/src/cpp.properties
	# Some of these are reserved for future use.
	# https://developer.mozilla.org/en/JavaScript/Reference/Reserved_Words
	'application/javascript' => [
		[   qw{
				abstract boolean break byte case catch char class
				const continue debugger default delete do double else enum export extends
				final finally float for function goto if implements import in instanceof
				int interface long native new package private protected public
				return short static super switch synchronized this throw throws
				transient try typeof var void volatile while with
				}
		]
	],

	# CSS keyword list is obtained from src/scite/src/css.properties
	'text/css' => [
		[

			# CSS1
			qw{
				color background-color background-image background-repeat background-attachment background-position background
				font-family font-style font-variant font-weight font-size font
				word-spacing letter-spacing text-decoration vertical-align text-transform text-align text-indent line-height
				margin-top margin-right margin-bottom margin-left margin
				padding-top padding-right padding-bottom padding-left padding
				border-top-width border-right-width border-bottom-width border-left-width border-width
				border-top border-right border-bottom border-left border
				border-color border-style width height float clear
				display white-space list-style-type list-style-image list-style-position list-style
				}
		],
		[

			# CSS2
			qw{
				border-top-color border-right-color border-bottom-color border-left-color border-color
				border-top-style border-right-style border-bottom-style border-left-style border-style
				top right bottom left position z-index direction unicode-bidi
				min-width max-width min-height max-height overflow clip visibility content quotes
				counter-reset counter-increment marker-offset
				size marks page-break-before page-break-after page-break-inside page orphans widows
				font-stretch font-size-adjust unicode-range units-per-em src
				panose-1 stemv stemh slope cap-height x-height ascent descent widths bbox definition-src
				baseline centerline mathline topline text-shadow
				caption-side table-layout border-collapse border-spacing empty-cells speak-header
				cursor outline outline-width outline-style outline-color
				volume speak pause-before pause-after pause cue-before cue-after cue
				play-during azimuth elevation speech-rate voice-family pitch pitch-range stress richness
				speak-punctuation speak-numeral
				}

		],
		[

			# CSS3
			qw{
				border-radius border-top-right-radius border-bottom-right-radius border-bottom-left-radius
				border-top-left-radius box-shadow columns column-width column-count column-rule column-gap
				column-rule-color column-rule-style column-rule-width resize opacity word-wrap
				}
		],

		# HTML keyword list is obtained from src/scite/src/css.properties
		'text/html' => [
			[

				# HTML elements
				qw{a abbr acronym address applet area b base basefont
					bdo big blockquote body br button caption center
					cite code col colgroup dd del dfn dir div dl dt em
					fieldset font form frame frameset h1 h2 h3 h4 h5 h6
					head hr html i iframe img input ins isindex kbd label
					legend li link map menu meta noframes noscript
					object ol optgroup option p param pre q s samp
					script select small span strike strong style sub sup
					table tbody td textarea tfoot th thead title tr tt u ul
					var xml xmlns
					},

				# HTML attributes
				qw{abbr accept-charset accept accesskey action align alink
					alt archive axis background bgcolor border
					cellpadding cellspacing char charoff charset checked cite
					class classid clear codebase codetype color cols colspan
					compact content coords
					data datafld dataformatas datapagesize datasrc datetime
					declare defer dir disabled enctype event
					face for frame frameborder
					headers height href hreflang hspace http-equiv
					id ismap label lang language leftmargin link longdesc
					marginwidth marginheight maxlength media method multiple
					name nohref noresize noshade nowrap
					object onblur onchange onclick ondblclick onfocus
					onkeydown onkeypress onkeyup onload onmousedown
					onmousemove onmouseover onmouseout onmouseup
					onreset onselect onsubmit onunload
					profile prompt readonly rel rev rows rowspan rules
					scheme scope selected shape size span src standby start style
					summary tabindex target text title topmargin type usemap
					valign value valuetype version vlink vspace width
					text password checkbox radio submit reset
					file hidden image
					^data-
					},

				# HTML 5 elements
				qw{
					address article aside audio base canvas command details datalist embed
					figure figcaption footer header hgroup keygen mark menu meter nav output
					progress ruby rt rp section source time video wbr
					},

				# HTML 5 attributes
				qw{
					async autocomplete autofocus contenteditable contextmenu draggable
					form formaction formenctype formmethod formnovalidate formtarget
					list manifest max min novalidate pattern placeholder
					required reversed role sandbox scoped seamless sizes spellcheck srcdoc step
					},
			],
		],
	],
);
$SCINTILLA_KEY_WORDS{'text/x-c++src'} = $SCINTILLA_KEY_WORDS{'text/x-c'};
$SCINTILLA_KEY_WORDS{'text/x-perlxs'} = $SCINTILLA_KEY_WORDS{'text/x-c'};





#####################################################################
# Task Integration

sub task_functions {
	return '';
}

sub task_outline {
	return '';
}

sub task_syntax {
	return '';
}





#####################################################################
# Document Registration

# NOTE: This is probably a bad place to store this
my $UNSAVED = 0;





#####################################################################
# Constructor and Accessors

use Class::XSAccessor {
	getters => {
		unsaved      => 'unsaved',
		filename     => 'filename',    # setter is defined as normal function
		file         => 'file',        # Padre::File - object
		editor       => 'editor',
		timestamp    => 'timestamp',
		mimetype     => 'mimetype',
		encoding     => 'encoding',
		errstr       => 'errstr',
		tempfile     => 'tempfile',
		highlighter  => 'highlighter',
		outline_data => 'outline_data',
	},
	setters => {
		set_editor       => 'editor',
		set_timestamp    => 'timestamp',
		set_mimetype     => 'mimetype',
		set_encoding     => 'encoding',
		set_newline_type => 'newline_type',
		set_errstr       => 'errstr',
		set_tempfile     => 'tempfile',
		set_highlighter  => 'highlighter',
		set_outline_data => 'outline_data',
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
				$self->current->main->info( $_[1] );
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

		if ( $self->{file}->exists ) {

			# Test script must be able to pass an alternate config object
			# NOTE: Since when do we support per-document configuration objects?
			my $config = $self->{config} || $self->current->config;
			if ( defined( $self->{file}->size ) and ( $self->{file}->size > $config->editor_file_size_limit ) ) {
				my $ret = Wx::MessageBox(
					sprintf(
						Wx::gettext(
							"The file %s you are trying to open is %s bytes large. It is over the arbitrary file size limit of Padre which is currently %s. Opening this file may reduce performance. Do you still want to open the file?"
						),
						$self->{file}->{filename},
						_commafy( -s $self->{file}->{filename} ),
						_commafy( $config->editor_file_size_limit )
					),
					Wx::gettext("Warning"),
					Wx::YES_NO | Wx::CENTRE,
					$self->current->main,
				);
				if ( $ret != Wx::YES ) {
					return;
				}
			}
		}
		$self->load_file;
	} else {
		$self->{unsaved}      = ++$UNSAVED;
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

	# NOTE: Hacky support for the Padre Popularity Contest
	unless ( defined $ENV{PADRE_IS_TEST} ) {
		my $popcon = $self->current->ide->{_popularity_contest};
		$popcon->count( 'mime.' . $self->mimetype ) if $popcon;
	}

	return $self;
}

sub rebless {
	my $self = shift;

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
			die "Failed to load $class: $@" if $@;
		}
		bless $self, $class;
	}

	my $module   = Padre::MimeTypes->get_current_highlighter_of_mime_type($mime_type);
	my $filename = '';                                                                # Not undef
	$filename = $self->{file}->filename
		if defined( $self->{file} )
			and defined( $self->{file}->{filename} );
	if ( not $module ) {
		$self->current->main->error(
			sprintf(
				Wx::gettext("No module mime_type='%s' filename='%s'"),
				$mime_type, $filename
			)
		);
	}
	$self->set_highlighter($module);

	return;
}

sub current {
	Padre::Current->new( document => $_[0] );
}

# Abstract methods, each subclass should implement it
# TO DO: Clearly this isn't ACTUALLY abstract (since they exist)

sub scintilla_word_chars {
	return '';
}

sub scintilla_key_words {
	my $self = shift;
	my $mime = $self->mimetype or return [];
	$SCINTILLA_KEY_WORDS{$mime} or return [];
}

sub get_calltip_keywords {
	return {};
}

sub get_function_regex {
	return '';
}

#
# $doc->get_comment_line_string;
#
# this is of course dependant on the language, and thus it's actually
# done in the subclasses. however, we provide base empty methods in
# order for padre not to crash if user wants to un/comment lines with
# a document type that did not define those methods.
#
# TO DO Remove this base method
sub get_comment_line_string {
	my $self = shift;
	my $mime = $self->mimetype or return;
	$COMMENT_LINE_STRING{$mime} or return;
}





######################################################################
# Padre::Cache Integration

# The detection of VERSION allows us to make this call without having
# to load modules at document destruction time if it isn't needed.
sub DESTROY {
	if ( defined $_[0]->{filename} and $Padre::Cache::VERSION ) {
		Padre::Cache->release( $_[0]->{filename} );
	}
}





#####################################################################
# Padre::Document GUI Integration

sub colourize {
	my $self   = shift;
	my $lexer  = $self->lexer;
	my $editor = $self->editor;
	$editor->SetLexer($lexer);
	TRACE("colourize called") if DEBUG;

	$editor->remove_color;
	if ( $lexer == Wx::wxSTC_LEX_CONTAINER ) {
		$self->colorize;
	} else {
		TRACE("Colourize is being called") if DEBUG;
		$editor->Colourise( 0, $editor->GetLength );
		TRACE("Colourize completed") if DEBUG;
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

# For ts without a newline type
# TO DO: get it from config
sub default_newline_type {
	my $self = shift;

	# Very ugly hack to make the test script work
	if ( $0 =~ /t.70_document\.t/ ) {
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
	$_[0]->current->main->message( $_[1], Wx::gettext('Error') );
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

sub is_unsaved {
	return !!( $_[0]->editor->GetModify and defined $_[0]->file );
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

sub is_readonly {
	my $self = shift;

	my $file = $self->file;
	return 0 unless defined($file);

	# Fill the cache if it's empty and assume read-write as a default
	$self->{readonly} ||= $self->file->readonly || 0;

	return $self->{readonly};
}

# Returns true if file has changed on the disk
# since load time or the last time we saved it.
# Check if the file on the disk has changed
# 1) when document gets the focus (gvim, notepad++)
# 2) when we try to save the file (gvim)
# 3) every time we type something ????
sub has_changed_on_disk {
	my $self = shift;
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

sub timestamp_now {
	my $self = shift;
	my $file = $self->file;
	return 0 unless defined $file;

	# It's important to return undef if there is no ->mtime for this filetype
	return undef unless $file->can('mtime');
	return $file->mtime;
}

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
	my $self = shift;
	my $file = $self->file;

	if (DEBUG) {
		my $name = $file->{filename} || '';
		TRACE("Loading file '$name'");
	}

	# Show the file-changed-dialog again after the file was (re)loaded:
	delete $self->{_already_popup_file_changed};

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
	require Encode;
	$content = Encode::decode( $self->{encoding}, $content );

	# Determine new line type using file content.
	$self->{newline_type} = Padre::Util::newline_type($content);

	# Cache the original value of various things so we can do
	# smart things at save time later.
	$self->{original_content} = $content;
	$self->{original_newline} = $self->{newline_type};

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
	my $key    = $event->GetUnicodeKey;
	unless ( $table{$key} ) {
		return 0;
	}

	# Is autocomplete enabled
	my $current = $self->current;
	my $config  = $current->config;
	unless ( $config->autocomplete_brackets ) {
		return 0;
	}

	# Is something selected?
	my $pos  = $editor->GetCurrentPos;
	my $text = $editor->GetSelectedText;
	if ( defined $text and length $text ) {
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
	my $self    = shift;
	my $current = $self->current;
	my $manager = $current->ide->plugin_manager;
	unless ( $manager->hook( 'before_save', $self ) ) {
		return;
	}

	# Show the file-changed-dialog again after the file was saved:
	delete $self->{_already_popup_file_changed};

	# If padre is run on files that have no project
	# I.E Padre foo.pl &
	# The assumption of $self->project as defined will cause a fail
	my $config;
	$config = $self->project->config if $self->project;
	$self->set_errstr('');

	if ( $config and $config->save_autoclean ) {
		$self->autoclean;
	}

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
			Wx::YES_NO | Wx::CENTRE,
			$current->main,
		);

		return 0 if $ret == Wx::YES;
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

	$manager->hook( 'after_save', $self );

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
	my $self = shift;
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

sub text_length {
	$_[0]->editor->GetLength;
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
	my $text   = $self->text_get or return;
	my $nlchar = "\n";
	if ( $self->newline_type eq 'WIN' ) {
		$nlchar = "\r\n";
	} elsif ( $self->newline_type eq 'MAC' ) {
		$nlchar = "\r";
	}
	$text =~ s/$nlchar/\n/g;
	return $text;
}

sub text_replace {
	my $self = shift;
	my $to   = shift;
	my $from = $self->text_get;

	# Generate a delta and apply it
	require Padre::Delta;

	#TODO Please implement the text_patch method or remove
	#$self->text_patch(
	#	Padre::Delta->from_scalars( \$from, \$to )
	#);
}

sub text_delta {
	my $self = shift;
	my $delta = Params::Util::_INSTANCE( shift, 'Padre::Delta' ) or return;
	$delta->apply( $self->editor );
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
		$self->current->main->error(
			sprintf(
				Wx::gettext("no highlighter for mime-type '%s' using stc"),
				$self->mimetype
			)
		);
		$highlighter = 'stc';
	}
	TRACE("The highlighter is '$highlighter'") if DEBUG;
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
		$self->{unsaved} ||= ++$UNSAVED;
		my $str = sprintf(
			Wx::gettext("Unsaved %d"),
			$self->{unsaved},
		);

		# A bug in Wx requires a space at the front of the title
		# (For reasons I don't understand yet)
		return ' ' . $str;
	}
}

# TO DO: experimental
sub get_indentation_style {
	my $self   = shift;
	my $config = $self->current->config;

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

=head2 C<event_on_context_menu>

NOT IMPLEMENTED IN THE BASE CLASS

This method - if implemented - is called when a user triggers the context menu
(either by right-click or the context menu key or Shift+F10) in an editor after
the standard context menu was created and populated in the C<Padre::Wx::Editor>
class.
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
	my $self    = shift;
	my $manager = $self->current->ide->project_manager;

	# If we have a cached project_dir return the object based on that
	if ( defined $self->{project_dir} ) {
		return $manager->project( $self->{project_dir} );
	}

	# Anonymous files don't have a project
	my $file = $self->file or return;

	# Currently no project support for remote files
	return unless $file->{protocol} eq 'local';

	# Find the project for this document's filename
	my $project = $manager->from_file( $file->{filename} );
	return undef unless defined $project;

	# To prevent the creation of tons of references to the project object,
	# cache the project by it's root directory.
	$self->{project_dir} = $project->root;

	return $project;
}

sub project_dir {
	my $self = shift;
	unless ( defined $self->{project_dir} ) {

		# Find the project, which slightly bizarely caches the
		# location of the project via it's root.
		# NOTE: Yes this looks weird, but it is significantly
		# less weird than the code it replaced.
		$self->project;
	}
	return $self->{project_dir};
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
	my $text = $self->text_get;

	# Hand off to the standalone module
	my $indentation = 'u'; # Unknown
	if ( length $text ) {

		# Allow for the delayed loading of Text::FindIndent if we startup
		# with no file or a completely empty file.
		require Text::FindIndent;
		$indentation = Text::FindIndent->parse(
			\$text,
			skip_pod => $self->isa('Padre::Document::Perl'),
		);
	}

	my $style;
	my $config = $self->current->config;
	if ( $indentation =~ /^t\d+/ ) { # we only do ONE tab
		$style = {
			use_tabs    => 1,
			tabwidth    => $config->editor_indent_tab_width || 8,
			indentwidth => 8,
		};
	} elsif ( $indentation =~ /^s(\d+)/ ) {
		$style = {
			use_tabs    => 0,
			tabwidth    => $config->editor_indent_tab_width || 8,
			indentwidth => $1,
		};
	} elsif ( $indentation =~ /^m(\d+)/ ) {
		$style = {
			use_tabs    => 1,
			tabwidth    => $config->editor_indent_tab_width || 8,
			indentwidth => $1,
		};
	} else {

		# fallback
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

sub functions {
	my $self = shift;
	my $task = Params::Util::_DRIVER( $self->task_functions, 'Padre::Task' ) or return;
	$task->find( $self->text_get );
}

sub pre_process {
	return 1;
}

sub selection_stats {
	my $self    = shift;
	my $text    = $self->editor->GetSelectedText;
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
	my $self                = shift;
	my $chars_without_space = 0;
	my $words               = 0;
	my $editor              = $self->editor;
	my $text                = $self->text_get;
	my $lines               = $editor->GetLineCount;
	my $chars_with_space    = $editor->GetTextLength;

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





#####################################################################
# Document Manipulation Methods

# Delete all leading spaces.
# Passes through to the editor by default, and is only defined in the
# document class so that document classes can overload and do special stuff.
sub delete_leading_spaces {
	my $self = shift;
	my $editor = $self->editor or return;
	return $editor->delete_leading_spaces;
}

# Delete all trailing spaces.
# Passes through to the editor by default, and is only defined in the
# document class so that document classes can overload and do special stuff.
sub delete_trailing_spaces {
	my $self = shift;
	my $editor = $self->editor or return;
	return $editor->delete_trailing_spaces;
}





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
	my $last = $editor->GetLength;
	my $text = $editor->GetTextRange( 0, $last );
	my $pre  = $editor->GetTextRange( 0, $first + length($prefix) );
	my $post = $editor->GetTextRange( $first, $last );

	my $regex = eval {qr{\b(\Q$prefix\E\w+)\b}};
	return ("Cannot build regular expression for '$prefix'.") if $@;

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

sub _commafy {
	my $number = reverse shift;
	$number =~ s/(\d{3})(?=\d)/$1,/g;
	return scalar reverse $number;
}

1;

# Copyright 2008-2011 The Padre development team as listed in Padre.pm.
# LICENSE
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl 5 itself.
