#!/usr/bin/env perl

use 5.010;
use strict;
use warnings;
use diagnostics;
use utf8;
use autodie;

use English qw( -no_match_vars );

our $VERSION = '0.001';

use Data::Printer { caller_info => 1 };
use Text::Diff::Parser;
#todo open test1.pl test2.pl
# generate a unified patch file
my $tf1 = 'test1.pl';
if ( -e $tf1 ){
	say "found 1: $tf1";
}

CORE::open( FH1, $tf1 );
my @fc1 = <FH1>;
CORE::close(FH1);
# say @fc1;
# p @fc1;

# my $diff1 = diff( 'test1.pl', 'test2.pl' );
# say $diff1;

my $tf2 = 'test3.pl';
if ( -e $tf2){
	say "found 2: $tf2";
}
CORE::open( FH2, $tf2 );
my @fc2 = <FH2>;
CORE::close(FH2);
# say @fc2;
# p @fc2;

say 'about 1 diff1';
my $diff1 = diff ( "test1.pl", "test2.pl", { STYLE => "Unified" } );
say $diff1;

say 'about 2 diff2';
my $diff2 = diff ( $tf1, $tf2,  { STYLE => "Unified" } );
say $diff2;

say 'about 3 diff3';
my $diff3 = diff ( \@fc1, \@fc2, { STYLE => "Unified" } );
say $diff3;


my $tf3 = 'test.patch';
CORE::open( FH3, $tf3 );
# CORE::close(FH1);
CORE::close(FH3);
say 'end';

1;

__END__
Text::Diff::Parser 
sub on_diff {
	my $self     = shift;
	my $document = $self->current->document or return;
	my $text     = $document->text_get;
	my $file     = defined( $document->{file} ) ? $document->{file}->filename : undef;
	unless ($file) {
		return $self->error( Wx::gettext("Cannot diff if file was never saved") );
	}

	my $external_diff = $self->config->external_diff_tool;

	if ($external_diff) {
		my $dir = File::Temp::tempdir( CLEANUP => 1 );

		my $filename = File::Spec->catdir(
			$dir,
			'IN_EDITOR' . File::Basename::basename($file)
		);

		if ( CORE::open( my $fh, '>', $filename ) ) {
			# print $fh $text;

			CORE::close($fh);
			system( $external_diff, '-ua', $file, $filename );


		} else {
			$self->error($!);
		}

		# save current version in a temp directory
		# run the external diff on the original and the launch the
	} else {
		require Text::Diff;
		
		my $diff = Text::Diff::diff( $file, \$text, { STYLE => 'Unified' });
		unless ($diff) {
			$diff = Wx::gettext("There are no differences\n");
		}

		$self->show_output(1);
		$self->output->clear;
		$self->output->AppendText($diff);
	}

	return;
}


__END__