package Padre::Plugin::PDL::Util;

use 5.008;
use strict;
use warnings;

our $VERSION = '0.05';

sub add_pdl_keywords_highlighting {
	my $document = shift;
	my $editor   = shift;

	my $keywords = Padre::Wx::Scintilla->keywords($document);
	if ( Params::Util::_ARRAY($keywords) ) {
		foreach my $i ( 0 .. $#$keywords ) {
			my $keyword_list = $keywords->[$i];
			if ( $i == 0 ) {
				$keyword_list .= ' ' . get_pdl_keywords();
			}
			$editor->Wx::Scintilla::TextCtrl::SetKeyWords( $i, $keyword_list );
		}
	}

	return;
}

sub get_pdl_keywords {

	require PDL::Doc;

	# Find the pdl documentation
	my $pdldoc;
	DIRECTORY: for my $dir (@INC) {
		my $file = "$dir/PDL/pdldoc.db";
		if ( -f $file ) {
			$pdldoc = new PDL::Doc($file);
			last DIRECTORY;
		}
	}

	my @functions;
	if ( defined $pdldoc ) {
		@functions = keys $pdldoc->gethash;
	} else {
		@functions = ();
	}

	return join ' ', @functions;
}
