package Padre::Plugin::SVN::Wx::BlameTree;

use 5.008;
use strict;
use warnings;
use Padre::Wx ();

our $VERSION = '0.05';
our @ISA     = 'Wx::TreeCtrl';

sub new {
	my $class  = shift;
	my $parent = shift;
	my $self   = $class->SUPER::new(
		$parent,
		-1,
		Wx::wxDefaultPosition,
		[ 700, 450 ],
		Wx::wxTR_HAS_BUTTONS | Wx::wxTR_HIDE_ROOT | Wx::wxTR_LINES_AT_ROOT | Wx::wxSUNKEN_BORDER |
		Wx::wxTR_FULL_ROW_HIGHLIGHT | Wx::wxTR_NO_LINES
	);

	$self->{root} = $self->AddRoot(
		'Root',
		-1,
		-1,
		Wx::TreeItemData->new('Data'),
	);

	# Set alternate colour
	my $bg_color = Wx::SystemSettings::GetColour( Wx::wxSYS_COLOUR_WINDOW );
	$self->{altColor} = Wx::Colour->new(
		int( $bg_color->Red   * 0.9 ),
		int( $bg_color->Green *0.9 ),
		$bg_color->Blue
	);

	return $self;
}

sub populate {
	my $self     = shift;
	my $blame    = shift;
	my $alt      = 0;
	my $setAlt   = 0;
	my $lastSeen = -1;

	for ( my $i=0; $i < scalar(@$blame); $i++ ) {
		$setAlt  = ($alt % 2 == 0) ? 1 : 0;

		my $line = $blame->[$i];
		chomp($line);
		$line =~ s/^\s+//s;
		$line =~ m/^(\d+)\s/;
		my $revNo = $1;

		# Grab the next lines revno
		my $next = $self->_get_next_revNo($i, $blame);

		my $item = $self->AppendItem(
			$self->{root},
			$line,
			1,
			1,
			Wx::TreeItemData->new($line)
		);

		# If we now have a following line that belongs to this revno
		# then keep working through the log file until
		# this is no longer the case, then set $i to the
		# index value of $j.
		if($next > 0 && $next == $revNo) {
			# Keep a track of the index for the revNo
			my $revNoIndex = $i;

			while( $next == $revNo ) {
				$i++;
				$line = $blame->[$i];
				$self->add_child($item,$line,$i, $revNo, $revNoIndex, $setAlt);

				$next = $self->_get_next_revNo($i, $blame);
			}

		}

		if( $setAlt ) {
			$self->SetItemBackgroundColour( $item, $self->{altColor} );
		}
		$alt++;
		$lastSeen = $revNo;
		$self->Expand($item);
	}
}

sub add_child {
	my( $self, $parent, $line, $index, $revNo, $revNoIndex, $setAlt ) = @_;
	my $item = $self->AppendItem(
		$parent,
		$line,
		1,
		1,
		Wx::TreeItemData->new($line)
	);
	if( $setAlt ) {
		$self->SetItemBackgroundColour( $item, $self->{altColor} );
	}
	my $t = Wx::TreeItemData->new;
	$t->SetData( $revNo .'-'. $revNoIndex );
	$self->SetItemData($item,$t);
}

sub _get_next_revNo {
	my($self,$index, $log) = @_;

	my $next = -1;
	if( $index + 1 < scalar(@$log) ) {
		my $line = $log->[$index+1];
		$line =~ s/^\s+//s;
		$line =~ m/^(\d+)\s/;
		$next = $1;
	}

	return $next;
}

1;
