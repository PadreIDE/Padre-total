package Padre::Document;

=head1 NAME

Padre::Document - document abstraction layer

=head1 DESCRIPTION

This is an internal module of L<Padre> that provides a 
logical document abstraction, allowing Padre to associate 
several Wx elements with the one document.

The objective would be to allow the use of this module without
loading Wx.

Currently there are still interdependencies that need to be cleaned.

=head1 METHODS

=cut

use 5.008;
use strict;
use warnings;
use Carp        ();
use File::Spec  ();
use Padre::Util ();
use Padre::Wx   ();

our $VERSION = '0.18';

my $unsaved_number = 0;

our %mode = (
	WIN  => Wx::wxSTC_EOL_CRLF,
	MAC  => Wx::wxSTC_EOL_CR,
	UNIX => Wx::wxSTC_EOL_LF,
);

# see Wx-0.86/ext/stc/cpp/st_constants.cpp for extension
# There might be some constants are defined in 
#  wxWidgets-2.8.8/contrib/include/wx/stc/stc.h 
# but not (yet) in 
#  Wx-0.86/ext/stc/cpp/st_constants.cpp
# so we have to hard-code their numeric value.

	# asp => wxSTC_LEX_ASP, #in ifdef
#	,
#	f     => wxSTC_LEX_FORTRAN,
	#     => wxSTC_LEX_VB, # What's the difference between VB and VBSCRIPT?

# partially made-up MIME-types; some parts extracted from /etc/mime.types
# Someone should go over and see if there are official mime-type definitions
# missing from the languages list
our %EXT_MIME = (
	ada   => 'text/x-adasrc',
	asm   => 'text/asm',
	bat   => 'text/bat',
	cpp   => 'text/x-c++src',
	css   => 'text/css',
	diff  => 'text/x-patch',
	e     => 'text/eiffel',
	f     => 'text/x-fortran',
	html  => 'text/html',
	js    => 'text/ecmascript',
	json  => 'text/ecmascript',
	latex => 'text/latex',
	lsp   => 'text/lisp',
	lua   => 'text/lua',
	mak   => 'text/x-makefile',
	mat   => 'text/matlab',
	pas   => 'text/x-pascal',
	php   => 'application/x-php',
	py    => 'text/x-python',
	rb    => 'application/x-ruby',
	sql   => 'text/x-sql',
	tcl   => 'text/x-tcl',
	vbs   => 'text/vbscript',
	patch => 'text/x-patch',
	pl    => 'application/x-perl',
	plx   => 'application/x-perl',
	pm    => 'application/x-perl',
	pod   => 'application/x-perl',
	t     => 'application/x-perl',
	xml   => 'text/xml',
	yml   => 'text/yaml',
	yaml  => 'text/yaml',
	'4th' => 'text/forth',
	pasm  => 'application/x-pasm',
	pir   => 'application/x-pir',
	p6    => 'application/x-perl6',
);

our %MIME_CLASS = (
	'application/x-perl'  => 'Padre::Document::Perl',
	'application/x-perl6' => 'Padre::Document::Perl6',
	'application/x-pasm'  => 'Padre::Document::Pasm',
	'application/x-pir'   => 'Padre::Document::Pir',
	'text/ecmascript'     => 'Padre::Document::JavaScript',
);

our %MIME_LEXER = (
	'text/x-adasrc'       => Wx::wxSTC_LEX_ADA,
	'text/asm'            => Wx::wxSTC_LEX_ASM,
	'text/bat'            => Wx::wxSTC_LEX_BATCH,
	'text/x-c++src'       => Wx::wxSTC_LEX_CPP,
	'text/css'            => Wx::wxSTC_LEX_CSS,
	'text/x-patch'        => Wx::wxSTC_LEX_DIFF,
	'text/eiffel'         => Wx::wxSTC_LEX_EIFFEL,
	'text/forth'          => Wx::wxSTC_LEX_FORTH,
	'text/x-fortran'      => Wx::wxSTC_LEX_FORTRAN,
	'text/html'           => Wx::wxSTC_LEX_HTML,
	'text/ecmascript'     => Wx::wxSTC_LEX_ESCRIPT,
	'text/latex'          => Wx::wxSTC_LEX_LATEX,
	'text/lisp'           => Wx::wxSTC_LEX_LISP,
	'text/lua'            => Wx::wxSTC_LEX_LUA,
	'text/x-makefile'     => Wx::wxSTC_LEX_MAKEFILE,
	'text/matlab'         => Wx::wxSTC_LEX_MATLAB,
	'text/x-pascal'       => Wx::wxSTC_LEX_PASCAL,
	'application/x-perl'  => Wx::wxSTC_LEX_PERL,
	'text/x-python'       => Wx::wxSTC_LEX_PYTHON,
	'application/x-php'   => Wx::wxSTC_LEX_PHPSCRIPT,
	'application/x-ruby'  => Wx::wxSTC_LEX_RUBY,
	'text/x-sql'          => Wx::wxSTC_LEX_SQL,
	'text/x-tcl'          => Wx::wxSTC_LEX_TCL,
	'text/vbscript'       => Wx::wxSTC_LEX_VBSCRIPT,
	'text/xml'            => Wx::wxSTC_LEX_XML,
	'text/yaml'           => Wx::wxSTC_LEX_YAML,
	'application/x-pir'   => Wx::wxSTC_LEX_CONTAINER,
	'application/x-pasm'  => Wx::wxSTC_LEX_CONTAINER,
	'application/x-perl6' => Wx::wxSTC_LEX_CONTAINER,
);

our $DEFAULT_LEXER = Wx::wxSTC_LEX_AUTOMATIC;



#####################################################################
# Constructor and Accessors

=head2 new

 my $doc = Padre::Document->new(
		editor   => $editor,
		filename => $file,
 );
 
$editor is required and is a Padre::Wx::Editor object

$file is optional and if given it will be loaded in the document

mime-type is defined by the guess_mimetype function

=cut

sub new {
	my $class = shift;
	my $self  = bless { @_ }, $class;
	
	# Check and derive params
	unless ( $self->editor ) {
		die "Missing or invalid editor";
	}

	$self->setup;

	unless ( $self->mimetype ) {
		$self->set_mimetype( $self->guess_mimetype );
	}
	$self->rebless;

	return $self;
}

sub rebless {
	my ($self) = @_;

	# Rebless as either to a subclass if there is a mime-type or
	# to the the base class, 
	# This isn't exactly the most elegant way to do this, but will
	# do for a first implementation.
	my $subclass = $MIME_CLASS{$self->mimetype} || __PACKAGE__;
	if ( $subclass ) {
                require Class::Autouse;
		Class::Autouse->autouse($subclass);
		bless $self, $subclass;
	}
	
	return;
}

sub guess_mimetype {
	my $self = shift;

	# default mime-type of new files, should be configurable in the GUI
	if (not $self->filename) {
		return 'application/x-perl';
	}

	# Try derive the mime type from the name
	if ( $self->filename and $self->filename =~ /\.([^.]+)$/ ) {
		my $ext = lc $1;
		return $EXT_MIME{$ext} if $EXT_MIME{$ext};
	}

	# Fall back on deriving the type from the content
	# Hardcode this for now for the special cases we care about.
	my $text = $self->text_get;
	if ( $text =~ /\A#!/m ) {
		# Found a hash bang line
		if ( $text =~ /\A#![^\n]*\bperl\b/m ) {
			return 'application/x-perl';
		}
	}

	# Fall back to a null value
	return '';
}

sub setup {
	my $self = shift;
	if ( $self->{filename} ) {
		$self->{newline_type} = $self->load_file($self->{filename}, $self->editor);
	} else {
		$unsaved_number++;
		$self->{newline_type} = $self->_get_default_newline_type;
	}
}

sub get_title {
	my $self = shift;
	if ( $self->{filename} ) {
		return File::Basename::basename( $self->{filename} );
	} else {
		return " Unsaved $unsaved_number";
	}
}

# For ts without a newline type
# TODO: get it from config
sub _get_default_newline_type {
	Padre::Util::NEWLINE;
}

# Where to convert (UNIX, WIN, MAC)
# or Ask (the user) or Keep (the garbage)
# mixed files
# TODO get from config
sub _mixed_newlines {
	Padre::Util::NEWLINE;
}

# What to do with files that have inconsistent line endings:
# 0 if keep as they are
# MAC|UNIX|WIN convert them to the appropriate type
sub _auto_convert {
	my ($self) = @_;
	# TODO get from config
	return 0;
}

sub load_file {
	my ($self, $file, $editor) = @_;

	require File::Slurp;
	my $newline_type = $self->_get_default_newline_type;
	my $convert_to;
	my $content = eval { File::Slurp::read_file($file, binmode => ':raw') };
	if ($@) {
		warn $@;
		return;
	}
	$self->{_timestamp} = $self->time_on_file;
	my $current_type = Padre::Util::newline_type($content);
	if ($current_type eq 'None') {
		# keep default
	} elsif ($current_type eq 'Mixed') {
		my $mixed = $self->_mixed_newlines();
		if ( $mixed eq 'Ask') {
			warn "TODO ask the user what to do with $file";
			# $convert_to = $newline_type = ;
		} elsif ( $mixed eq 'Keep' ) {
			warn "TODO probably we should not allow keeping garbage ($file) \n";
		} else {
			#warn "TODO converting $file";
			$convert_to = $newline_type = $mixed;
		}
	} else {
		$convert_to = $self->_auto_convert;
		if ($convert_to) {
			#warn "TODO call converting on $file";
			$newline_type = $convert_to;
		} else {
			$newline_type = $current_type;
		}
	}
	$editor->SetEOLMode( $mode{$newline_type} );

	$editor->SetText( $content );
	$editor->EmptyUndoBuffer;
	if ($convert_to) {
		warn "Converting $file to $convert_to";
		$editor->ConvertEOLs( $mode{$newline_type} );
	}

	return ($newline_type);
}

sub save_file {
	my ($self) = @_;
	my $content  = $self->text_get;
	my $filename = $self->filename;
        
	require File::Slurp;
	eval {
		File::Slurp::write_file($filename, {binmode => ':raw'}, $content);
	};
	if ($@) {
		return "Could not save: $@";
	}
	$self->{_timestamp} = $self->time_on_file;

	return;
}

sub set_newline_type {
	$_[0]->{newline_type} = $_[1];
}

sub get_newline_type {
	$_[0]->{newline_type};
}

sub filename {
	$_[0]->{filename};
}

# Temporary hack
sub _set_filename {
	$_[0]->{filename} = $_[1];
}

sub mimetype {
	$_[0]->{mimetype};
}
sub set_mimetype {
	$_[0]->{mimetype} = $_[1];
}

sub lexer {
	my $self = shift;
	return $DEFAULT_LEXER unless $self->mimetype;
	return $DEFAULT_LEXER unless defined $MIME_LEXER{$self->mimetype};
	return $MIME_LEXER{$self->mimetype};
}

# Cache for speed reasons
sub editor {
	$_[0]->{editor};
}

sub is_new {
	return !! ( not defined $_[0]->filename );
}

sub is_modified {
	return !! ( $_[0]->editor->GetModify );
}

# check if the file on the disk has changed
# 1) when document gets the focus (gvim, notepad++)
# 2) when we try to save the file (gvim)
# 3) every time we type something ????

# returns if file has changed on the disk 
# since load time or the last time we saved
sub has_changed_on_disk {
	my ($self) = @_;
	return 0 if not defined $self->filename;
	return 0 if not defined $self->last_sync;
	return $self->last_sync < $self->time_on_file ? 1 : 0;
}

sub time_on_file {
	return 0 if not defined $_[0]->filename;
	return 0 if not -e $_[0]->filename;
	return (stat($_[0]->filename))[9];
}

sub last_sync {
	return $_[0]->{_timestamp};
}

# A new document that isn't worth saving
sub is_unused {
	my $self = shift;
	return '' unless $self->is_new;
	return 1  unless $self->is_modified;
	return 1  if     $self->text_get eq '';
	return '';
}

sub is_saved {
	return !! ( defined $_[0]->filename and not $_[0]->is_modified );
}

sub reload {
	my ($self) = @_;

	my $filename = $self->filename or return;
	$self->load_file($filename, $self->editor);
	return 1;
}

=head2 can_check_syntax

Returns a B<true> value if the class provides a method C<check_syntax>
for retrieving information on syntax errors and warnings in the 
current document.

The method in this base class returns B<false>.

=cut

sub can_check_syntax {
	return 0;
}

=head2 check_syntax ( [ FORCE ] )

NOT IMPLEMENTED IN THIS BASE CLASS

An implementation in a derived class needs to return an arrayref of
syntax problems.
Each entry in the array has to be an anonymous hash with the 
following keys:

=over 4

=item * line

The line where the problem resides

=item * msg

A short description of the problem

=item * severity

A flag indicating the problem class: Either 'B<W>' (warning) or 'B<E>' (error)

=item * desc

A longer description with more information on the error (currently 
not used but intended to be)

=back

Returns an empty arrayref if no problems can be found.

Returns B<undef> if nothing has changed since the last invocation.

Must return the problem list even if nothing has changed when a 
param is present which evaluates to B<true>.

=cut



#####################################################################
# Content Manipulation

sub text_get {
	$_[0]->editor->GetText;
}

sub text_set {
	$_[0]->editor->SetText($_[1]);
}

sub text_like {
	my $self = shift;
	return !! ( $self->text_get =~ /$_[0]/m );
}





#####################################################################
# Project Methods

sub project_dir {
	my $self = shift;
	$self->{project_dir} or
	$self->{project_dir} = $self->find_project;
}

sub find_project {
	my $self = shift;

	# Anonmous files don't have a project
	unless ( defined $self->filename ) {
		return;
	}

	# Search upwards from the file to find the project root
	my ($v, $d, $f) = File::Spec->splitpath( $self->filename );
	my @d = File::Spec->splitdir($d);
	pop @d if $d[-1] eq '';
	require List::Util;
	my $dirs = List::Util::first {
		-f File::Spec->catpath( $v, $_, 'Makefile.PL' )
		or
		-f File::Spec->catpath( $v, $_, 'Build.PL' )
		or
		# Some notional Padre project file
		-f File::Spec->catpath( $v, $_, 'padre.proj' )
	} map {
		File::Spec->catdir(@d[0 .. $_])
	} reverse ( 0 .. $#d );

	unless ( defined $dirs ) {
		# This document is not part of a recognised project
		return;
	}

	return File::Spec->catpath( $v, $dirs );
}

# abstract method, each subclass should implement it
sub keywords           { return {} }
sub get_functions      { return () };
sub get_function_regex { return '' };

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
	my $prefix = $editor->GetTextRange($first, $pos);
	   $prefix =~ s{^.*?((\w+::)*\w+)$}{$1};
	my $last   = $editor->GetLength();
	my $text   = $editor->GetTextRange(0, $last);

	my $regex;
	eval { $regex = qr{\b($prefix\w*(?:::\w+)*)\b} };
	if ($@) {
		return ("Cannot build regex for '$prefix'");
	}
	my %seen;
	my @words = grep { ! $seen{$_}++ } sort ($text =~ /$regex/g);
	if (@words > 20) {
		@words = @words[0..19];
	}

	return (length($prefix), @words);
}

sub remove_color {
	my ($self) = @_;

	my $editor = $self->editor;
	# TODO this is strange, do we really need to do it with all?
	for my $i ( 0..31 ) {
		$editor->StartStyling(0, $i);
		$editor->SetStyling($editor->GetLength, 0);
	}

	return;
}

#
# $doc->comment_lines_str;
#
# this is of course dependant on the language, and thus it's actually
# done in the subclasses. however, we provide base empty methods in
# order for padre not to crash if user wants to un/comment lines with
# a document type that did not define those methods.
#
sub comment_lines_str {}

sub stats {
	my ($self) = @_;
	
	my ( $lines, $chars_with_space, $chars_without_space, $words, $is_readonly )
		= (0) x 5;

	my $editor = $self->editor;
	my $src = $editor->GetSelectedText;
	my $code;
	if ( $src ) {
		$code = $src;

		my $code2 = $code; # it's ugly, need improvement
		$code2 =~ s/\r\n/\n/g;
		$lines = 1; # by default
		$lines++ while ( $code2 =~ /[\r\n]/g );
		$chars_with_space = length($code);
    } else {
		$code = $self->text_get;

		# I trust editor more
		$lines = $editor->GetLineCount();
		$chars_with_space = $editor->GetTextLength();
		$is_readonly = $editor->GetReadOnly();
	}
    
	$words++ while ( $code =~ /\b\w+\b/g );
	$chars_without_space++ while ( $code =~ /\S/g );

	my $filename = $self->filename;
	
	return ( $lines, $chars_with_space, $chars_without_space, $words, $is_readonly, $filename);
}

1;

# Copyright 2008 Gabor Szabo.
# LICENSE
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl 5 itself.
