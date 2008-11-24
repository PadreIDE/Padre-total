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

sub LineFromPosition {
	my ($self, $pos) = @_;
	return 0 if $pos == 0;
	my $str = substr($self->{text}, 0, $pos);
	#warn "str $pos '$str'\n";
	my @lines = split /\n/, $str, -1;
	return @lines-1; 
}

sub GetLineEndPosition {
	my ($self, $line) = @_;
	my @lines = split(/\n/, $self->{text}, -1);
	my $str = join "\n", @lines[0..$line];
	return length($str)+1;
}
sub PositionFromLine {
	my ($self, $line) = @_;

	return 0 if $line == 0;
	my @lines = split(/\n/, $self->{text}, -1);
	my $str = join "\n", @lines[0..$line-1];
	return length($str)+1;
}

# ??
sub GetColumn {
	my ($self, $pos) = @_;
	my $line = $self->LineFromPosition($pos);
	my $start = $self->PositionFromLine($line);
	return $pos-$start;
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
