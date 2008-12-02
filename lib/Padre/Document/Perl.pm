package Padre::Document::Perl;

use 5.008;
use strict;
use warnings;

use Carp            ();
use Params::Util    '_INSTANCE';
use YAML::Tiny      ();
use PPI;

use Padre::Document ();
use Padre::Util     ();

our $VERSION = '0.20';
our @ISA     = 'Padre::Document';





#####################################################################
# Padre::Document::Perl Methods

sub ppi_get {
	my $self = shift;
	my $text = $self->text_get;
	require PPI::Document;
	PPI::Document->new( \$text );
}

sub ppi_set {
	my $self     = shift;
	my $document = _INSTANCE(shift, 'PPI::Document');
	unless ( $document ) {
		Carp::croak("Did not provide a PPI::Document");
	}

	# Serialize and overwrite the current text
	$self->text_set( $document->serialize );
}

sub ppi_find {
	my $self     = shift;
	my $document = $self->ppi_get;
	return $document->find( @_ );
}

sub ppi_find_first {
	my $self     = shift;
	my $document = $self->ppi_get;
	return $document->find_first( @_ );
}

sub ppi_transform {
	my $self      = shift;
	my $transform = _INSTANCE(shift, 'PPI::Transform');
	unless ( $transform ) {
		Carp::croak("Did not provide a PPI::Transform");
	}

	# Apply the transform to the document
	my $document = $self->ppi_get;
	unless ( $transform->document($document) ) {
		Carp::croak("Transform failed");
	}
	$self->ppi_set($document);

	return 1;
}

sub ppi_select {
	my $self     = shift;
	my $location = shift;
	if ( _INSTANCE($location, 'PPI::Element') ) {
		$location = $location->location;
	}
	my $editor   = $self->editor or return;
	my $line     = $editor->PositionFromLine( $location->[0] - 1 );
	my $start    = $line + $location->[1] - 1;
	$editor->SetSelection( $start, $start + 1 );
}

my $keywords;

sub keywords {
	unless ( defined $keywords ) {
		$keywords = YAML::Tiny::LoadFile(
			Padre::Util::sharefile( 'languages', 'perl5', 'perl5.yml' )
		);
	}
	return $keywords;
}

sub get_functions {
	my $self = shift;
	my $text = $self->text_get;
	return reverse sort $text =~ m{^sub\s+(\w+(?:::\w+)*)}gm;
}

sub get_function_regex {
	my ( $self, $sub ) = @_;
	return qr{(^|\n)sub\s+$sub\b};
}


sub get_command {
	my $self     = shift;

	# Check the file name
	my $filename = $self->filename;
	unless ( $filename and $filename =~ /\.pl$/i ) {
		die "Only .pl files can be executed\n";
	}

	# Run with the same Perl that launched Padre
	# TODO: get preferred Perl from configuration
	my $perl = Padre->perl_interpreter;

	my $dir = File::Basename::dirname($filename);
	chdir $dir;
	return qq{"$perl" "$filename"};
}

sub colorize {
	my ($self) = @_;
	
	$self->remove_color;

	my $editor = $self->editor;
	my $text   = $self->text_get;
	
	my $ppi_doc = PPI::Document->new( \$text );
	if (not defined $ppi_doc) {
		Wx::LogMessage( 'PPI::Document Error %s', PPI::Document->errstr );
		Wx::LogMessage( 'Original text: %s', $text );
		return;
	}

	my %colors = (
		keyword         => 4, # dark green
		structure       => 6,
		core            => 1, # red
		pragma          => 7, # purple
		'Whitespace'    => 0,
		'Structure'     => 0,

		'Number'        => 1,
		'Float'         => 1,
		
		'HereDoc'       => 4,
		'Data'          => 4,
		'Operator'      => 6,
		'Comment'       => 2, # it's good, it's green
		'Pod'           => 2,
		'End'           => 2,
		'Label'         => 0,
		'Word'          => 0, # stay the black
		'Quote'         => 9,
		'Single'        => 9,
		'Double'        => 9,
		'Interpolate'   => 9,
		'QuoteLike'     => 7,
		'Regexp'        => 7,
		'Words'         => 7,
		'Readline'      => 7,
		'Match'         => 3,
		'Substitute'    => 5,
		'Transliterate' => 5,
		'Separator'     => 0,
		'Symbol'        => 0,
		'Prototype'     => 0,
		'ArrayIndex'    => 0,
		'Cast'          => 0,
		'Magic'         => 0,
    );

	my @tokens = $ppi_doc->tokens;
	$ppi_doc->index_locations;
	my $first = $editor->GetFirstVisibleLine();
	my $lines = $editor->LinesOnScreen();
	#print "First $first lines $lines\n";
	foreach my $t (@tokens) {
		#print $t->content;
		my ($row, $rowchar, $col) = @{ $t->location };
#		next if $row < $first;
#		next if $row > $first + $lines;
		my $css = $self->_css_class($t);
#		if ($row > $first and $row < $first + 5) {
#			print "$row, $rowchar, ", $t->length, "  ", $t->class, "  ", $css, "  ", $t->content, "\n";
#		}
#		last if $row > 10;
		my $color = $colors{$css};
		if (not defined $color) {
			Wx::LogMessage("Missing definition fir '$css'\n");
			next;
		}
		next if not $color;

		my $start  = $editor->PositionFromLine($row-1) + $rowchar-1;
		my $len = $t->length;

		$editor->StartStyling($start, $color);
		$editor->SetStyling($len, $color);
	}
}


sub _css_class {
	my ($self, $Token) = @_;
	if ( $Token->isa('PPI::Token::Word') ) {
		# There are some words we can be very confident are
		# being used as keywords
		unless ( $Token->snext_sibling and $Token->snext_sibling->content eq '=>' ) {
			if ( $Token->content =~ /^(?:sub|return)$/ ) {
				return 'keyword';
			} elsif ( $Token->content =~ /^(?:undef|shift|defined|bless)$/ ) {
				return 'core';
			}
		}
		
		if ( $Token->previous_sibling and $Token->previous_sibling->content eq '->' ) {
			if ( $Token->content =~ /^(?:new)$/ ) {
				return 'core';
			}
		}

		if ( $Token->parent->isa('PPI::Statement::Include') ) {
			if ( $Token->content =~ /^(?:use|no)$/ ) {
				return 'keyword';
			}
			if ( $Token->content eq $Token->parent->pragma ) {
				return 'pragma';
			}
		} elsif ( $Token->parent->isa('PPI::Statement::Variable') ) {
			if ( $Token->content =~ /^(?:my|local|our)$/ ) {
				return 'keyword';
			}
		} elsif ( $Token->parent->isa('PPI::Statement::Compond') ) {
			if ( $Token->content =~ /^(?:if|else|elsif|unless|for|foreach|while|my)$/ ) {
				return 'keyword';
			}
		} elsif ( $Token->parent->isa('PPI::Statement::Package') ) {
			if ( $Token->content eq 'package' ) {
				return 'keyword';
			}
		} elsif ( $Token->parent->isa('PPI::Statement::Scheduled') ) {
			return 'keyword';
		}
	}

	# Normal coloring
	my $css = ref $Token;
	$css =~ s/^.+:://;
	$css;
}

sub can_check_syntax {
	return 1;
}

sub check_syntax {
	my $self  = shift;
    my $force = shift;

	my $txt = $self->text_get;
	return [] unless defined($txt) && $txt;

	unless ($force) {
		if (   defined( $self->{last_checked_txt} )
			&& $self->{last_checked_txt} eq $txt
		) {
			return undef;
		}
	}
	$self->{last_checked_txt} = $txt;

	my $report = '';
	{
		require File::Temp;

		my $fh = File::Temp->new();
		my $fname = $fh->filename;
		print $fh $txt;
		$report = `$^X -Mdiagnostics -c $fname 2>&1 1>/dev/null`;
	}

	# Don't really know where that comes from...
	my $i = index( $report, 'Uncaught exception from user code' );
	if ( $i > 0 ) {
		$report = substr( $report, 0, $i );
	}

	my $nlchar = "\n";
	if ( $self->get_newline_type eq 'WIN' ) {
		$nlchar = "\r\n";
	}
	elsif ( $self->get_newline_type eq 'MAC' ) {
		$nlchar = "\r";
	}

	return [] if $report =~ /\A[^\n]+syntax OK$nlchar\z/o;

	$report =~ s/$nlchar$nlchar/$nlchar/go;
	$report =~ s/$nlchar\s/\x1F /go;
	my @msgs = split(/$nlchar/, $report);

	my $issues = [];
	my @diag = ();
	foreach my $msg ( @msgs ) {
		if (   index( $msg, 'has too many errors' )    > 0
			or index( $msg, 'had compilation errors' ) > 0
			or index( $msg, 'syntax OK' ) > 0
		) {
			last;
		}

		my $cur = {};
		my $tmp = '';

		if ( $msg =~ s/\s\(\#(\d+)\)\s*\Z//o ) {
			$cur->{diag} = $1 - 1;
		}

		if ( $msg =~ m/\)\s*\Z/o ) {
			my $pos = rindex( $msg, '(' );
			$tmp = substr( $msg, $pos, length($msg) - $pos, '' );
		}

		if ( $msg =~ s/\s\(\#(\d+)\)(.+)//o ) {
			$cur->{diag} = $1 - 1;
			my $diagtext = $2;
			$diagtext =~ s/\x1F//go;
			push @diag, join( ' ', split( ' ', $diagtext ) );
		}

		if ( $msg =~ s/\sat(?:\s|\x1F)+.+?(?:\s|\x1F)line(?:\s|\x1F)(\d+)//o ) {
			$cur->{line} = $1;
			$cur->{msg}  = $msg;
		}

		if ($tmp) {
			$cur->{msg} .= "\n" . $tmp;
		}

		$cur->{msg} =~ s/\x1F/$nlchar/go;

		if ( defined $cur->{diag} ) {
			$cur->{desc} = $diag[ $cur->{diag} ];
			delete $cur->{diag};
		}
		if (   defined( $cur->{desc} )
			&& $cur->{desc} =~ /^\s*\([WD]/o
		) {
			$cur->{severity} = 'W';
		}
		else {
			$cur->{severity} = 'E';
		}

		push @{$issues}, $cur;
	}

	return $issues;
}

sub comment_lines_str { return '#' }


sub find_unmatched_brace {
	my ($self) = @_;

	my $ppi   = $self->ppi_get or return;
	my $where = $ppi->find( \&Padre::PPI::find_unmatched_brace );
	if ( $where ) {
		@$where = sort {
			Padre::PPI::element_depth($b) <=> Padre::PPI::element_depth($a)
			or
			$a->location->[0] <=> $b->location->[0]
			or
			$a->location->[1] <=> $b->location->[1]
		} @$where;
		$self->ppi_select( $where->[0] );
		return 1;
	}
	return 0;
}

1;

# Copyright 2008 Gabor Szabo.
# LICENSE
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl 5 itself.
