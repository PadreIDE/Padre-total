use STD;

package Padre::Document::Perl6;

use 5.010;
use strict;
use warnings;
use feature qw(say);
use English '-no_match_vars';  # Avoids regex performance penalty
use Padre::Document ();

use Benchmark;
use Syntax::Highlight::Perl6;

our $VERSION = '0.22';
our @ISA     = 'Padre::Document';

my $keywords;

# Naive way to parse and colorize perl6 files
sub colorize {
	my ($self, $first) = @_;

	my $editor = $self->editor;
	my $text   = $self->text_get;
  
  my $t0 = Benchmark->new;
  my $p = Syntax::Highlight::Perl6->new(
    text => $text,
  );
  
  my @tokens;

	eval {
	@tokens = $p->tokens;
  1;
	};
	
	if($EVAL_ERROR) {
		say "Parsing error, bye bye ->colorize";
		return;
	}
	
	$self->remove_color;
	
  my %colors = (
		'comp_unit'  => Px::PADRE_BLUE, 
		'scope_declarator' => Px::PADRE_DARK_RED,
		'routine_declarator' => Px::PADRE_DARK_RED,
		'regex_declarator' => Px::PADRE_DARK_RED,
		'package_declarator' => Px::PADRE_DARK_RED,
		'statement_control' => Px::PADRE_DARK_RED,
		'block' => Px::PADRE_BLACK,
		'regex_block' => Px::PADRE_BLACK,
		'noun' => Px::PADRE_BLACK,
		'sigil' => Px::PADRE_DARK_GREEN,
		'variable' => Px::PADRE_DARK_GREEN, 
		'assertion' => Px::PADRE_DARK_GREEN,
		'quote' => Px::PADRE_DARK_MAGENTA,
		'number' => Px::PADRE_DARK_ORANGE,
		'infix' => Px::PADRE_DIM_GRAY,
		'methodop' => Px::PADRE_BLACK,
		'pod_comment' => Px::PADRE_DARK_GREEN,
		'param_var' => Px::PADRE_CRIMSON,
		'_scalar' => Px::PADRE_DARK_RED,
		'_array' => Px::PADRE_BROWN,
		'_hash' => Px::PADRE_DARK_ORANGE,
		'_comment' => Px::PADRE_DARK_GREEN,
  );
  for my $htoken (@tokens) {
    my %token = %{$htoken};
    my $color = $colors{ $token{rule} };
    if($color) {
      my $len = length $token{buffer};
      my $start = $token{last_pos} - $len;
      $editor->StartStyling($start, $color);
      $editor->SetStyling($len, $color);
    }
  }
  
  my $td = timediff(new Benchmark, $t0);
  say "->colorize took:" . timestr($td) ;  
}

sub get_command {
	my $self     = shift;
	
	my $filename = $self->filename;

	if (not $ENV{PARROT_PATH}) {
		die "PARROT_PATH is not defined. Need to point to trunk of Parrot SVN checkout.\n";
	}
	my $parrot = File::Spec->catfile($ENV{PARROT_PATH}, 'parrot');
	if (not -x $parrot) {
		die "$parrot is not an executable.\n";
	}
	my $rakudo = File::Spec->catfile($ENV{PARROT_PATH}, 'languages', 'perl6', 'perl6.pbc');
	if (not -e $rakudo) {
		die "Cannot find Rakudo ($rakudo)\n";
	}

	return qq{"$parrot" "$rakudo" "$filename"};

}

sub keywords {
	if (! defined $keywords) {
		$keywords = YAML::Tiny::LoadFile(
			Padre::Util::sharefile( 'languages', 'perl6', 'perl6.yml' )
		);
	}
	return $keywords;
}

sub comment_lines_str { return '#' }

1;

# Copyright 2008 Gabor Szabo.
# LICENSE
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl 5 itself.
