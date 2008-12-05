#!/usr/bin/perl

use strict;
use warnings;
use Test::NeedsDisplay;
use Test::More;
use File::Spec  ();
use t::lib::Padre;
use t::lib::Padre::Editor;

my $tests;
plan tests => $tests;

use Padre::Document;
use Padre::PPI;

my $editor_1 = t::lib::Padre::Editor->new;
my $file_1   = File::Spec->catfile('t', 'files', 'missing_brace_1.pl');
my $doc_1    = Padre::Document->new(
	filename  => $file_1,
);
	#editor    => $editor_1, 

SCOPE: {
	isa_ok($doc_1, 'Padre::Document');
	isa_ok($doc_1, 'Padre::Document::Perl');
	is($doc_1->filename, $file_1, 'filename');
	
	#Padre::PPI::find_unmatched_brace();
	BEGIN { $tests += 3; }
}


# tests for Padre::PPI::find_variable_declaration
SCOPE: {
  my $infile = File::Spec->catfile('t', 'files', 'find_variable_declaration_1.pm');
  my $text = do { local $/=undef; open my $fh, '<', $infile or die $!; <$fh> };
  
  my $doc = PPI::Document->new( \$text );
  isa_ok($doc, "PPI::Document");
  $doc->index_locations;
  
  my $elem;
  $doc->find_first(
    sub {
      return 0 if not $_[1]->isa('PPI::Token::Symbol')
               or not $_[1]->content eq '$n_threads_to_kill'
               or not $_[1]->location->[0] == 138;
      $elem = $_[1];
      return 1;
    }
  );
  isa_ok( $elem, 'PPI::Token::Symbol' );

  my $declaration;
  $doc->find_first(
    sub {
      return 0 if not $_[1]->isa('PPI::Statement::Variable')
               or not $_[1]->location->[0] == 126;
      $declaration = $_[1];
      return 1;
    }
  );
  isa_ok( $declaration, 'PPI::Statement::Variable' );

  my $result_declaration = Padre::PPI::find_variable_declaration($elem);

  ok( $declaration == $result_declaration, 'Correct declaration found');

  BEGIN { $tests += 4; }
}


