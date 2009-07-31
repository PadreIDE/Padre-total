package Padre::Wx::Directory::SearchTask2;

use strict;
use warnings;

our $VERSION = '0.41';
use base 'Padre::Task';

# Search recursively in $project_dir for files
# that its name matchs the type word
sub run {
	my $self = shift;

	# Searchs below the project directory and caches it
	@{$self->{result}} = $self->_search( $self->{project_dir} );

	return 1;
}

sub finish {
	my $self        = shift;
	my $directory   = shift->directory;
	my $project_dir = $self->{project_dir};
	my $search      = $directory->{search};
	my $tree        = $directory->{tree};
	my $word        = $self->{word};
	$self->{tree}   = $tree;

	# Returns if there is no result to be displayed
	return "BREAK" unless $self->{result};

	# Returns if the requested word is not the
	# currently searched word (e.g. New word typed
	# during the delayed search)
	return "BREAK" if $word ne $search->GetValue;

	# Cleans the Directory Browser window to
	# show the result
	my $root = $tree->GetRootItem;
	$tree->DeleteChildren( $root );

	# Displays the cached search result
	$self->_display_search_result( $root, $self->{result} );

	# Caches the searched word and result to the project
	$search->{CACHED}->{ $project_dir }->{value} = $word;
	$search->{CACHED}->{ $project_dir }->{data}  = $self->{result};

	# Expands all the folders to the files matched
	$tree->ExpandAll;

	# Shows the Cancel button
	$search->ShowCancelButton(1);

	return 1;
}

# Searchs recursively per items that matchs the REGEX typed in search field,
# showing all items matched below the ROOT project directory will all the
# folders that paths to them expanded.
sub _search {
	my ( $self, $path ) = @_;
	my $cache       = $self->{cache};
	my $tree        = $self->{tree};
	my $search      = $self->{search};
	my $word        = $self->{word};
	my $project_dir = $self->{project_dir};

	# Fetch the ignore criteria
# Note: Just works with .pl files
#	my $project = $self->current->project;
#	$rule = $project ? $project->ignore_rule : undef;

	# If there is a Cached Word (in case that the user is still typing)
	if ( my $last_word = $cache->{$project_dir}->{value} ){
		# Quotes meta characters
		$last_word = quotemeta($last_word);

		# If the typed word contains the cached word, use Cached result to do
		# the new search and returns the result
		if ( $word =~ /$last_word/i ) {
			return $self->_search_in_cache( $cache->{$project_dir}->{data} );
		}
	}

	# Opens the current directory and sort its items by type and name
	my ($dirs, $files) = $tree->readdir( $path );

	# Quotes meta characters
	$word = quoteword( $word );

	# Filter the file list by the search criteria (but not the dir list)
	@$files = grep { $_ =~ /$word/i } @$files;

	# Search recursively inside each folder of the current folder
	my @result = ();
	foreach ( @$dirs ) {

		my %temp = (
			name => $_,
			dir  => $path,
			type => 'folder',
		);

		# Are we ignoring this directory
		if ( $search->{skip_hidden}->IsChecked ) {
#			if ( $rule ) {
#				local $_ = \%temp;
#				unless ( $rule->() ) {
#					next;
#				}
#			} elsif ( $temp{name} =~ /^\./ ) {
			if ( $temp{name} =~ /^\./ ) {
				next;
			}
		}

		# Skips VCS folders if selected to
		if ( $search->{skip_vcs}->IsChecked ) {
			if ( $temp{name} =~ /^(cvs|blib|\.(svn|git))$/i ) {
				next;
			}
		}
		if ( @{$temp{data}} = $self->_search( File::Spec->catdir( $path, $temp{name} ) ) ) {
			push @result, \%temp;
		}
	}

	# Adds each matched file
	foreach ( @$files ) {
		push @result, {
			name => $_,
			dir  => $path,
			type => 'package',
		};
	}

	# Returns 1 if any file above this path node was found or 0 and
	# deletes parent node if none
	return @result;
}

sub _search_in_cache {
	my $self = shift;
	my $data = shift;

	# Quotes meta characters
	my $word = quoteword($self->{word});

	# Goes thought each item from $data, if is a folder , searchs
	# recursively inside it, if is a file tries to match its name
	my @result = ();
	foreach ( @$data ) {
		# If it is a folder, searchs recursively below it
		if ( defined $_->{data} ) {
			my %temp = (
				dir  => $_->{dir},
				name => $_->{name},
				type => $_->{type}
			);
			if ( @{$temp{data}} = $self->_search_in_cache( $_->{data} ) ) {
				push @result, \%temp;
			}
		} else {
			# Adds each matched file
			if ( $_->{name} =~ /$word/i ) {
				push @result, {
					name => $_->{name},
					dir  => $_->{dir},
					type => 'package',
				};
			}
		}
	}
	return @result;
}

sub _display_search_result {
	my ( $self, $node, $data ) = @_;
	my $tree      = $self->{tree};
	my $node_data = $tree->GetPlData( $node );
	my $path = File::Spec->catfile( $node_data->{dir}, $node_data->{name} );

	# Files that matchs and Dirs arrays
	my @dirs  = grep { $_->{type} eq 'folder'  } @{$data};
	my @files = grep { $_->{type} eq 'package' } @{$data};

	# Search recursively inside each folder of the current folder
	for (@dirs) {
		# Creates each folder node
		my $new_folder = $tree->AppendItem(
			$node, $_->{name},
			$tree->{file_types}->{folder}, -1,
			Wx::TreeItemData->new( {
				dir  => $path,
				name => $_->{name},
				type => 'folder',
			} )
		);
		$self->_display_search_result( $new_folder, $_->{data} );
	}

	# Adds each matched file
	foreach ( @files ) {
		$tree->AppendItem(
			$node,
			$_->{name},
			$tree->{file_types}->{package},	-1,
			Wx::TreeItemData->new( {
				dir  => $path,
				name => $_->{name},
				type => 'package',
			} )
		);
	}
}

# Quotes meta characters
# Accept some regex like characters
#   ^ = begin with
#   $ = end with
#   * = any string
#   ? = any character
sub quoteword {
	my $word = quotemeta(shift);
	$word =~ s/^\\\^/^/g;
	$word =~ s/\\\$$/\$/g;
	$word =~ s/\\\*/.*?/g;
	$word =~ s/\\\?/./g;

	return $word;
}

1;

