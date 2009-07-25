package Padre::Wx::Directory;

use strict;
use warnings;
use Padre::Wx                        ();
use Padre::Wx::Directory::TreeCtrl   ();
use Padre::Wx::Directory::SearchCtrl ();

our $VERSION = '0.41';
our @ISA     = 'Wx::Panel';

use Class::XSAccessor
getters => {
	tree     => 'tree',
	search   => 'search',
	fallback => 'fallback',
},
accessors => {
	project_dir  => 'project_dir',
	previous_dir => 'previous_dir',
};

# Creates the Directory Left Panel with a Search field
# and the Directory Browser
sub new {
	my $class = shift;
	my $main  = shift;

	# Create the parent panel, which will contain the search and tree
	my $self = $class->SUPER::new(
		$main->left,
		-1,
		Wx::wxDefaultPosition,
		Wx::wxDefaultSize,
	);

	# Creates the Search Field and the Directory Browser
	$self->{tree}   = Padre::Wx::Directory::TreeCtrl->new($self);
	$self->{search} = Padre::Wx::Directory::SearchCtrl->new($self);

	# Fill the panel
	my $sizerv = Wx::BoxSizer->new( Wx::wxVERTICAL );
	my $sizerh = Wx::BoxSizer->new( Wx::wxHORIZONTAL );
	$sizerv->Add( $self->search, 0, Wx::wxALL | Wx::wxEXPAND, 0 );
	$sizerv->Add( $self->tree,   1, Wx::wxALL | Wx::wxEXPAND, 0 );
	$sizerh->Add( $sizerv,       1, Wx::wxALL | Wx::wxEXPAND, 0 );

	# Fits panel layout
	$self->SetSizerAndFit($sizerh);
	$sizerh->SetSizeHints($self);

	# Sets default Directory Tree directory
	$DB::single = 1;
	$self->{fallback} = File::HomeDir->my_documents;

	return $self;
}

# Returns the left object reference (where the Directory Browser is placed)
sub left {
	$_[0]->GetParent;
}

# Returns the main object reference
sub main {
	$_[0]->GetGrandParent;
}

sub current {
	Padre::Current->new( main => $_[0]->main );
}

# Returns the window label
sub gettext_label {
	Wx::gettext('Directory');
}

# Updates the gui, so each compoment can update itself
# according to the new state
sub clear {
	$_[0]->refresh;
	return;
}

# Updates the gui if needed, calling Searcher and Browser respectives
# refresh function.
# Called outside Directory.pm, on directory browser focus and item dragging
sub refresh {
	my $self    = shift;
	my $current = $self->current;

	# Finds project base
	my $doc = $current->document;
	my $dir = $doc ? $doc->project_dir : $self->fallback;

	# Save the current project path
	$self->project_dir($dir);

	# Calls Searcher and Browser refresh
	$self->tree->refresh;
	$self->search->refresh;

	# Sets the last project to the current one
	$self->previous_dir($dir);

	return 1;
}

1;

# Copyright 2008-2009 The Padre development team as listed in Padre.pm.
# LICENSE
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl 5 itself.
