package Padre::Document::Perl;

use 5.008;
use strict;
use warnings;
use Carp            ();
use Params::Util    '_INSTANCE';
use Padre::Document ();
use YAML::Tiny      ();
use PPI;

our $VERSION = '0.15';
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
			Padre::Wx::sharefile( 'languages', 'perl5', 'perl5.yml' )
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
	return qr{sub\s+$sub\b};
}


sub get_command {
	my $self     = shift;

	# Check the file name
	my $filename = $self->filename;
	unless ( $filename =~ /\.pl$/i ) {
		die "Only .pl files can be executed\n";
	}

	# Run with the same Perl that launched Padre
	# TODO: get preferred Perl from configuration
	my $perl = Padre->perl_interpreter;

	my $dir = File::Basename::dirname($filename);
	chdir $dir;
	return qq{"$perl" "$filename"};
}

sub colourise {
	my ($self, $first) = @_;
	
	$self->remove_color;

	my $editor = $self->editor;
	my $text   = $self->text_get;
	
	my $doc = PPI::Document->new( \$text );
	if (not defined $doc) {
		print $text;
		return;
	}
    my @tokens = @{ $doc->find('PPI::Token') };

	# color 1 is for keywords
	my $keywords = $self->keywords;
    my %colors = (
		'PPI::Token::HereDoc'   => 4,
		'PPI::Token::Data'      => 4,
		'PPI::Token::Operator'  => 6,
		'PPI::Token::Comment'   => 2, # it's good, it's green
		'PPI::Token::Pod'       => 2,
		'PPI::Token::End'       => 2,
		'PPI::Token::Word'      => 0, # stay the black
		'PPI::Token::Quote'     => 9,
		'PPI::Token::QuoteLike' => 7,
		'PPI::Token::Regexp::Match'         => 3,
		'PPI::Token::Regexp::Substitute'    => 5,
		'PPI::Token::Regexp::Transliterate' => 5,
		'PPI::Token::Symbol'    => 0, # stay the black
		'PPI::Token::Prototype' => 0, # stay the black
    );

    my $pos = 0;
    foreach my $flag ( 0 .. $#tokens ) {
		my $token = $tokens[$flag];

		my $content; # original content
		if ( $token->isa('PPI::Token::HereDoc') ) {
			# XXX? hi, it's a bit breaking, but I don't know how to fix
			my @next_tokens;
			my $old_flag = $flag;
			while ( $old_flag++ ) {
				push @next_tokens, $tokens[$old_flag];
				last if ( $tokens[$old_flag]->content eq ';' );
			}
			$content = $token->content .
            join('', map { $_->content } @next_tokens ) . "\n" .
            join('', $token->heredoc) .
            $token->terminator;
		} else {
			$content = $token->content;
		}

		my $len = length($content);
		$pos += $len;
		
		my $color = 0;
		foreach my $token_isa ( keys %colors ) {
			# keywords has color 1
			if ( $token->isa('PPI::Token::Word') and grep { $token->content eq $_ } keys %$keywords ) {
				$color = 1;
				last;
			}
		
			if ( $token->isa( $token_isa ) ) {
				$color = $colors{ $token_isa };
				last;
			}
		}
		next unless ( $color );
		
		my $start  = $pos - $len;
		$editor->StartStyling($start, $color);
		$editor->SetStyling($len, $color);
    }
}


1;

# Copyright 2008 Gabor Szabo.
# LICENSE
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl 5 itself.
