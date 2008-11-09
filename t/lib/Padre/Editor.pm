package t::lib::Padre::Editor;
use strict;
use warnings;

sub new {
	return bless {}, shift;
}

sub SetEOLMode {
}

sub SetText {
	$_[0]->{text} = $_[1];
}

sub EmptyUndoBuffer {
}

sub ConvertEOLs {
}

sub  GetText {
}


1;
