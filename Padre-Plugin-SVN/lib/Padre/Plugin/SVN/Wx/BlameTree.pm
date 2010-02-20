package Padre::Plugin::SVN::Wx::BlameTree;

use 5.008;
use strict;
use warnings;
use Encode          ();
use Padre::Constant ();
use Padre::Wx       ();
use Padre::Locale   ();

use Wx qw(:treectrl :window wxDefaultPosition wxDefaultSize);

our $VERSION = '0.04';
our @ISA     = 'Wx::TreeCtrl';


sub new {
	my $class = shift;
	my $parent = shift;
	#my $blame= shift;
	
	my $self = $class->SUPER::new( 
		$parent,
		-1,
		Wx::wxDefaultPosition,
		Wx::wxDefaultSize,
		Wx::wxTR_HAS_BUTTONS | Wx::wxTR_HIDE_ROOT | Wx::wxTR_LINES_AT_ROOT
	);
	
	$self->{root} = $self->AddRoot(
		'Root',
		-1,
		-1,
		Wx::TreeItemData->new('Data'),
	);
	
	return $self;
}


sub populate {
	my $self = shift;
	my $blame = shift;
	
	my $altColor = 0;
	
	my @tbl;
	my $lastSeen = "";
	foreach my $line (@$blame) {
		
		chomp($line);
		$line =~ s/^\s+//s;
		$line =~ m/^(\d+)\s/;
		my $revNo = $1;
		
		#print "$line\n";
		#push @tbl, [ split(/\s+/,$line,3) ];
		my $item = $self->AppendItem(
			$self->{root}, 
			$line, 
			-1,
			-1,
			Wx::TreeItemData->new($line)
		);
		$altColor++ if( $lastSeen != $revNo );
		
		
		if( $altColor % 2 == 0 ) {
			$self->SetItemBackgroundColour( $item, Wx::wxBLUE );
		}

		$lastSeen = $revNo;
	}
	
}

1;