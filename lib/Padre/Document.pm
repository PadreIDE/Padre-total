package Padre::Document;

# Provides a logical document abstraction, allowing Padre
# to associate several Wx elements with the one document.

use strict;
use warnings;
use File::Spec ();
use List::Util ();

our $VERSION = '0.08';





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

	# Check params
	unless ( $self->page ) {
		die "Missing or invalid page_id";
	}

	return $self;
}

sub filename {
	$_[0]->{filename};
}

sub type {
	$_[0]->{type};
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
