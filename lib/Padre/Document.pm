package Padre::Document;

# Provides a logical document abstraction, allowing Padre
# to associate several Wx elements with the one document.

use 5.008;
use strict;
use warnings;
use Wx qw{
	wxSTC_LEX_PERL
	wxSTC_LEX_AUTOMATIC
};
use File::Spec ();
use List::Util ();

our $VERSION = '0.09';

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

our %MIME_CLASS = (
	'text/perl' => 'Padre::Document::Perl',
);

our %MIME_LEXER = (
	'text/perl' => wxSTC_LEX_PERL,
);

our $DEFAULT_LEXER = wxSTC_LEX_AUTOMATIC;

### DODGY HACK
# This is a temporary method that can generate an "anonymous"
# document for whatever is in the current buffer. The document
# is not saved or cached anywhere.
# This method may be changed to work properly later, but for now
# feel free to use it wherever needed.
sub from_selection {
	$_[0]->from_page_id( $_[0]->notebook->GetSelection );
}

sub from_page_id {
	my $class    = shift;
	my $page_id  = shift;
        if ( $page_id == -1 ) {
		# No page selected
		return;
        }
	my $page     = $class->notebook->GetPage( $page_id );
	my $filename = $page->{'Padre::Wx::MainWindow'}->{filename};
	my $document = $class->new(
		page_id  => $page_id,
		page     => $page,
		filename => $filename,
	);
	return $document;
}





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
			$self->{mimetype} = $EXT_MIME{$ext} if $EXT_MIME{$ext};
		}

		unless ( $self->mimetype ) {
			# Fall back on deriving the type from the content
			# Hardcode this for now for the special cases we care about.
			my $text = $self->text_get;
			if ( $text =~ /\A\#\!/m ) {
				# Found a hash bang line
				if ( $text =~ /\A[^\n]\bperl\b/m ) {
					$self->{mimetype} = 'text/perl';
				}
			}
		}

		# Fall back to a null value
		unless ( defined $self->mimetype ) {
			$self->{mimetype} = '';
		}
	}

	# If we blessed as the base class, and the mime type has a
	# specific subclass, rebless it.
	# This isn't exactly the most elegant way to do this, but will
	# do for a first implementation.
	if ( $class eq __PACKAGE__ ) {
		my $subclass = $MIME_CLASS{$self->mimetype};
		if ( $subclass ) {
			Class::Autouse->autouse($subclass);
			bless $self, $subclass;
		}
	}

	return $self;
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

sub lexer {
	my $self = shift;
	return $DEFAULT_LEXER unless $self->mimetype;
	return $DEFAULT_LEXER unless $MIME_LEXER{$self->mimetype};
	return $MIME_LEXER{$self->mimetype};
}

sub page_id {
	$_[0]->{page_id};
}

# Cache for speed reasons
sub page {
	$_[0]->{page} or
	$_[0]->{page} = $_[0]->notebook->GetPage( $_[0]->page_id );
}

sub is_new {
	return !! ( defined $_[0]->page_id and not defined $_[0]->filename );
}

sub is_modified {
	return !! ( $_[0]->page->GetModify );
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






#####################################################################
# Content Manipulation

sub text_get {
	$_[0]->page->GetText;
}

sub text_set {
	$_[0]->page->SetText($_[1]);
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
