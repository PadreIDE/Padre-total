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

our $VERSION = '0.21';
our @ISA     = 'Padre::Document';

# Naive way to parse and colorize perl6 files
sub colorize {
	my ($self, $first) = @_;

	my $editor = $self->editor;
	my $text   = $self->text_get;
  
  my $t0 = new Benchmark;
  my $p = new Syntax::Highlight::Perl6(
    text => $text,
  );
  
  my @parse_recs;

	eval {
	@parse_recs = @{ $p->parse_trees };
  1;
	};
	
	if($EVAL_ERROR) {
		say "Parsing error, bye bye ->colorize";
		return;
	}
	
	$self->remove_color;
	
  my %colors = (
		'comp_unit'  => 0, # color: Blue; 
		'scope_declarator' => 1, # color: DarkRed
		'routine_declarator' => 1, # color: DarkRed;
		'regex_declarator' => 1, #color: DarkRed;
		'package_declarator' => 1, #color DarkRed;
		'statement_control' => 1, #color: DarkRed;
		'block' => 0, # color: Black;
		'regex_block' => 0, #color: Black;
		'noun' => 0, #color: Black;
		'sigil' => 4, #color: DarkGreen;
		'variable' => 4, #color: DarkGreen; 
		'assertion' => 4, #color: Darkgreen;
		'quote' => => 7, #color: DarkMagenta;
		'number' => 7, #color: DarkOrange;
		'infix' => 3, #color: DimGray;
		'methodop' => 0, #color: black; font-weight: bold;
		'pod_comment' => 4, #color: DarkGreen; font-weight: bold;
		'param_var' => 7, #color: Crimson;
		'_routine' => 1, #color: DarkRed; font-weight: bold;
		'_type' => 1, #color: DarkBlue; font-weight: bold;
		'_scalar' => 1, #color: DarkBlue; font-weight: bold;
		'_array' => 1, #color: Brown; font-weight: bold;
		'_hash' => 1, #color: DarkOrange; font-weight: bold;
		'_comment' => 4, #color: DarkGreen; font-weight: bold;
  );
  for my $rec (@parse_recs) {
    my $pos = @{$rec}[0];
    my $buffer = @{$rec}[1];
    my $rule = @{$rec}[2];
    my $color = $colors{$rule};
    if($color) {
      my $len = length $buffer;
      my $start = $pos - $len;
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

sub comment_lines_str { return '#' }

1;

# Copyright 2008 Gabor Szabo.
# LICENSE
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl 5 itself.
