package Padre::Document;

# Provides a logical document abstraction, allowing Padre
# to associate several Wx elements with the one document.

use strict;
use warnings;
use Wx qw{
	wxSTC_LEX_PERL
	wxSTC_LEX_AUTOMATIC
};
use File::Spec ();
use List::Util ();

our $VERSION = '0.08';

# see Wx-0.84/ext/stc/cpp/st_constants.cpp for extension
# N.B. Some constants (wxSTC_LEX_ESCRIPT for example) are defined in 
#  wxWidgets-2.8.7/contrib/include/wx/stc/stc.h 
# but not (yet) in 
#  Wx-0.84/ext/stc/cpp/st_constants.cpp
# so we have to hard-code their numeric value.
our %SYNTAX = (
#	ada   => wxSTC_LEX_ADA,
#	asm   => wxSTC_LEX_ASM,
	# asp => wxSTC_LEX_ASP, #in ifdef
#	bat   => wxSTC_LEX_BATCH,
#	cpp   => wxSTC_LEX_CPP,
#	css   => wxSTC_LEX_CSS,
#	diff  => wxSTC_LEX_DIFF,
	#     => wxSTC_LEX_EIFFEL, # what is the default EIFFEL file extension?
	#     => wxSTC_LEX_EIFFELKW,
#	'4th' => wxSTC_LEX_FORTH,
#	f     => wxSTC_LEX_FORTRAN,
#	html  => wxSTC_LEX_HTML,
#	js    => 41, # wxSTC_LEX_ESCRIPT (presumably "ESCRIPT" refers to ECMA-script?) 
#	json  => 41, # wxSTC_LEX_ESCRIPT (presumably "ESCRIPT" refers to ECMA-script?)
#	latex => wxSTC_LEX_LATEX,
#	lsp   => wxSTC_LEX_LISP,
#	lua   => wxSTC_LEX_LUA,
#	mak   => wxSTC_LEX_MAKEFILE,
#	mat   => wxSTC_LEX_MATLAB,
#	pas   => wxSTC_LEX_PASCAL,
#	pl    => wxSTC_LEX_PERL,
#	pod   => wxSTC_LEX_PERL,
#	pm    => wxSTC_LEX_PERL,
#	php   => wxSTC_LEX_PHPSCRIPT,
#	py    => wxSTC_LEX_PYTHON,
#	rb    => wxSTC_LEX_RUBY,
#	sql   => wxSTC_LEX_SQL,
#	tcl   => wxSTC_LEX_TCL,
#	t     => wxSTC_LEX_PERL,
#	yml   => wxSTC_LEX_YAML,
#	yaml  => wxSTC_LEX_YAML,
#	vbs   => wxSTC_LEX_VBSCRIPT,
	#     => wxSTC_LEX_VB, # What's the difference between VB and VBSCRIPT?
#	xml   => wxSTC_LEX_XML,
#	_default_ => wxSTC_LEX_AUTOMATIC,
);

our %EXT_MIME = (
	pm  => 'text/perl',
	t   => 'text/perl',
	pl  => 'text/perl',
	plx => 'text/perl',
);

our %MIME_LEXER = (
	'text/perl' => wxSTC_LEX_PERL,
);

our $DEFAULT_LEXER = wxSTC_LEX_AUTOMATIC;





#####################################################################
# Class Methods

sub notebook {
	Padre->ide->wx->main_window->{notebook};
}





#####################################################################
# Constructor and Accessors

sub new {
	my $class = shift;
	my $self  = bless { @_ }, $class;

	# Check and derive params
	unless ( $self->page ) {
		die "Missing or invalid page_id";
	}
	unless ( $self->mimetype ) {
		# Try derive the mime type from the name
		if ( $self->filename and $self->filename =~ /\.([^.]+)$/ ) {
			my $ext = lc $1;
			return $EXT_MIME{$ext} if $EXT_MIME{$ext};
		}

		# Fall back on deriving the type from the content
		# Hardcode this for now for the special cases we care about.
		my $text = $self->get_text;
		if ( $text =~ /\A\#\!/m ) {
			# Found a hash bang line
			if ( $text =~ /\A[^\n]\bperl\b/m ) {
				return 'text/perl';
			}
		}
	}

	return $self;
}

sub filename {
	$_[0]->{filename};
}

sub mimetype {
	$_[0]->{mimetype};
}

sub lexer {
	my $self = shift;

	# Use the mimetype first
	if ( $self->mimetype ) {
		return $MIME_LEXER{$self->mimetype}
			|| $DEFAULT_LEXER;
	}

	# Otherwise guess
	my $text = $self->get_text;
	if ( $text =~ /\A\#\!/m ) {
		if ( $text =~ /\A[^\n]\bperl\b/m ) {
			return MIME_LEXER{'text/perl'};
		}
	}

	return $DEFAULT_LEXER;
}

sub page_id {
	$_[0]->{page_id};
}

# Cache for speed reasons
sub page {
	$_[0]->{page} or
	$_[0]->{page} = $_[0]->notebook->GetPage( $_[0]->page_id );
}

sub project_dir {
	my $self = shift;
	$self->{project_dir} or
	$self->{project_dir} = $self->find_project;
}





#####################################################################
# Content Manipulation

sub get_text {
	$_[0]->page->GetText;
}

sub set_text {
	$_[0]->page->SetText($_[1]);
}





#####################################################################
# System Interaction Methods

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

1;
