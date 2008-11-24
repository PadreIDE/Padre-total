package t::lib::Padre::Editor;
use strict;
use warnings;

sub new {
	my $self = bless {}, shift;
	return $self;
}

sub SetEOLMode {
}
sub ConvertEOLs {
}


sub EmptyUndoBuffer {
}

sub SetText {
	$_[0]->{text} = $_[1];
	$_[0]->{pos}  = 0;
}

sub GetText {
	return $_[0]->{text}
}

sub GetCurrentPos {
	return $_[0]->{pos};
}

sub GotoPos {
	$_[0]->{pos} = $_[1];
}

1;
