package Padre::Plugin::SQL::ResultsPanel;

# panel for the database stuff.
# stolen completely from the Catalyst plugin

use strict;
use warnings;

our $VERSION = '0.01';

use Padre::Wx ();
use Padre::Util ('_T');
use Wx ();

use Wx::Grid;

use base 'Wx::Panel';

sub new {
	my $class      = shift;
	my $main       = shift;
	my $self       = $class->SUPER::new( Padre::Current->main->bottom );

	require Scalar::Util;;
	$self->{main} = $main;
	Scalar::Util::weaken($self->{main});
	
	my $box = Wx::BoxSizer->new(Wx::wxVERTICAL);
	
	my $grid = Wx::Grid->new(
		$self,
		-1,
		[-1,-1],
		[-1,-1],
		
	);
	
	# output panel for server
	#require Padre::Wx::Output;
	#my $output = Padre::Wx::Output->new($self);
	
	#$box->Add( $output, 1, Wx::wxGROW );
	#$box->Add( $output, 1, Wx::wxGROW );	
	#$self->{output} = $output;
	
	$grid->CreateGrid( 5, 5 );
	$box->Add($grid, 1, Wx::wxGROW);
	$self->SetSizer($box);
	
	
	$self->{grid} = $grid;
	
	return $self;
}


sub output { return shift->{grid}; }
sub gettext_label { return _T('Database Results'); }

# dirty hack to allow seamless use of Padre::Wx::Output
sub bottom { return $_[0]; }

sub update_grid {
	my $self = shift;
	my $results = shift;
	
	print "update_grid()\n";
	my $numCols = scalar( @{ $results->[0] } );
	my $numRows = scalar(@{ $results->[1] } );
		
	print "rows: $numRows\n";
	print "columns $numCols\n";
	
	#my $grid = Wx::Grid->new(
	#	$self,
	#	-1,
	#	[-1,-1],
	#	[-1,-1],
	#	
	#);
	
	#
	
	$self->{grid}->ClearGrid;
	$self->{grid}->DeleteRows(0, $self->{grid}->GetNumberRows);
	$self->{grid}->DeleteCols(0, $self->{grid}->GetNumberCols);
	
	#$self->{grid}->CreateGrid($numRows, $numCols);
	$self->{grid}->AppendCols( $numCols );
	$self->{grid}->AppendRows( $numRows );
	
	
	for( my $i = 0; $i < $numCols; $i++ ) {
		$self->{grid}->SetColLabelValue($i, $results->[0][$i]);
	}
	
	for( my $i = 0; $i < $numRows; $i++ ) {
		for(my $j = 0; $j < $numCols; $j++ ) {
			$self->{grid}->SetCellValue($i, $j, $results->[1]->[$i]->[$j] );
		}
		
	}
	
	$self->{grid}->AutoSize;
	
	print join( ',', @{ $results->[0] } ) . "\n";
	#print out for now
	my $rowNum = 1;	
	foreach my $row( @{ $results->[1] } ) {
		#foreach my $col( @{ $row } ) {
		my $prtRow = "$rowNum: " . join(',', @{ $row } ) . "\n";
		#$msg_output->AppendText( $prtRow );
		print $prtRow;
		$rowNum++;
	}
	
	
	

}



1;

# Copyright 2008-2010 The Padre development team as listed in Padre.pm.
# LICENSE
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl 5 itself.