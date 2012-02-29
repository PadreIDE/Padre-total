package Padre::Plugin::Moose::Util;

use 5.008;
use strict;
use warnings;

our $VERSION = '0.14';

sub add_moose_keywords_highlighting {
	my $document = shift;
	my $editor = $document->editor or return;

	my $keywords = Padre::Wx::Scintilla->keywords($document);
	if ( Params::Util::_ARRAY($keywords) ) {
		foreach my $i ( 0 .. $#$keywords ) {
			my $keyword_list = $keywords->[$i];
			$keyword_list
				.= " has with extends before around after "
				. "override super augment inner type subtype "
				. "enum class_type as where coerce via from "
				. "requires excludes"
				if $i == 0;
			$editor->Wx::Scintilla::TextCtrl::SetKeyWords( $i, $keyword_list );
		}
	}

	return;
}
