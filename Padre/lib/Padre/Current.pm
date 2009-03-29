package Padre::Current;

# A context object, for centralising the concept of what is "current"

use strict;
use warnings;
use Carp         ();
use Exporter     ();
use Params::Util qw{_INSTANCE};

our $VERSION   = '0.32';
use base 'Exporter';
our @EXPORT_OK = '_CURRENT';





#####################################################################
# Exportable Functions

# This is an importable convenience function.
# It's current not as efficient as it should be, but once the majority
# of the context-sensitive code has been migrated over, we should be
# able to simplify it quite a bit.
sub _CURRENT {
	# Most likely options
	unless ( defined $_[0] ) {
		return Padre::Current->new;
	}
	if ( _INSTANCE($_[0], 'Padre::Current') ) {
		return shift;
	}

	# Fallback options
	if ( _INSTANCE($_[0], 'Padre::Document') ) {
		return Padre::Current->new( document => shift );
	}
	return Padre::Current->new;
}





#####################################################################
# Constructor

sub new {
	my $class = shift;
	bless { @_ }, $class;
}





#####################################################################
# Context Methods

# Get the project from the document (and don't cache)
sub project {
	my $self     = ref($_[0]) ? $_[0] : $_[0]->new;
	my $document = $self->document;
	if ( defined $document ) {
		return $document->project;
	} else {
		return undef;
	}
}
	
# Get the text from the editor (and don't cache)
sub text {
	my $self   = ref($_[0]) ? $_[0] : $_[0]->new;
	my $editor = $self->editor;
	if ( defined $editor ) {
		return $editor->GetSelectedText;
	} else {
		return undef;
	}
}

# Get the title of the current editor window (and don't cache)
sub title {
	my $self     = ref($_[0]) ? $_[0] : $_[0]->new;
	my $notebook = $self->notebook;
	my $selected = $notebook->GetSelection;
	if ( $selected >= 0 ) {
		return $notebook->GetPageText($selected);
	} else {
		return undef;
	}
}

# Get the filename from the document
sub filename {
	my $self = ref($_[0]) ? $_[0] : $_[0]->new;
	unless ( exists $self->{filename} ) {
		my $document = $self->document;
		if ( defined $document ) {
			$self->{filename} = $document->filename;
		} else {
			$self->{filename} = undef;
		}
	}
	return $self->{filename};
}

# Get the document from the editor
sub document {
	my $self = ref($_[0]) ? $_[0] : $_[0]->new;
	unless ( exists $self->{document} ) {
		my $editor = $self->editor;
		if ( defined $editor ) {
			$self->{document} = $editor->{Document};
		} else {
			$self->{document} = undef;
		}
	}
	return $self->{document};
}

# Derive the editor from the document
sub editor {
	my $self = ref($_[0]) ? $_[0] : $_[0]->new;
	unless ( exists $self->{editor} ) {
		my $notebook = $self->notebook;
		my $selected = $notebook->GetSelection;
		if ( $selected == -1 ) {
			$self->{editor} = undef;
		} elsif ( $selected >= $notebook->GetPageCount ) {
			$self->{editor} = undef;
		} else {
			$self->{editor} = $notebook->GetPage( $selected );
			unless ( $self->{editor} ) {
				Carp::croak("Failed to find page");
			}
		}
	}
	return $self->{editor};
}

# Convenience method
sub notebook {
	my $self = ref($_[0]) ? $_[0] : $_[0]->new;
	unless ( defined $self->{notebook} ) {
		$self->{notebook} = $self->main->notebook;
	}
	return $self->{notebook};
}

# Get the project from the main window (and don't cache)
sub config {
	my $self = ref($_[0]) ? $_[0] : $_[0]->new;
	$self->main->config;
}

# Convenience method
sub main {
	my $self = ref($_[0]) ? $_[0] : $_[0]->new;
	unless ( defined $self->{main} ) {
		if ( defined $self->{ide} ) {
			$self->{main} = $self->{ide}->wx->main;
		} else {
			require Padre;
			$self->{ide}  = Padre->ide;
			$self->{main} = $self->{ide}->wx->main;
		}
		return $self->{main};
	}
	return $self->{main};
}

# Convenience method
sub ide {
	my $self = ref($_[0]) ? $_[0] : $_[0]->new;
	unless ( defined $self->{ide} ) {
		if ( defined $self->{main} ) {
			$self->{ide} = $self->{main}->ide;
		} else {
			require Padre;
			$self->{ide} = Padre->ide;
		}
	}
	return $self->{ide};
}

1;

# Copyright 2008-2009 The Padre development team as listed in Padre.pm.
# LICENSE
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl 5 itself.
