package Padre::Plugin::SVN::Wx::SVNDialog;


use 5.008;
use warnings;
use strict;

use Padre::Wx     		();
use Padre::Wx::Dialog 		();
use Padre::Wx::Icon           	();

our @ISA = 'Wx::Dialog';

sub new {
	my $class = shift;
	my $main = shift;
	my $filePath = shift;
	my $log = shift;
	my $type = shift || '';
	my $getData = shift;
	
	my $self = $class->SUPER::new (
		$main,
		-1,
		"SVN $type",
		[200,300],
		[600,550],
	);
	$self->SetIcon(Padre::Wx::Icon::PADRE);
	
	$self->build_dialog($filePath, $log, $getData);
	
	#$self->build_padre_dialog( $filePath, $log);
	return $self;
	
	
}


sub build_dialog {
	my ($self, $file, $log, $getData) = @_;
	my $vbox = Wx::BoxSizer->new( Wx::wxVERTICAL );
	
	my $stTxtFile = Wx::StaticText->new( $self,
						-1,
						Wx::gettext("File: $file"),
						Wx::wxDefaultPosition,
						Wx::wxDefaultSize,
						0,
						""
						);
						
	$vbox->Add( $stTxtFile, 0, Wx::wxEXPAND  );
	
	#print "file: $file\n";
	#print "Log: $log\n";
	
	my $txtCtrl;
	if( $log ) {
		$txtCtrl = Wx::TextCtrl->new(
			   $self, 
			   -1,
			   "$log", 
			   Wx::wxDefaultPosition, 
			   [-1,-1], 
			   Wx::wxTE_MULTILINE | Wx::wxHSCROLL | Wx::wxVSCROLL
			  );
	}
	if( $getData ) {
		#print "getting data\n";
		$txtCtrl = Wx::TextCtrl->new(
			   $self, 
			   -1,
			   "Commit Message", 
			   Wx::wxDefaultPosition, 
			   [-1,-1], 
			   Wx::wxTE_MULTILINE | Wx::wxHSCROLL | Wx::wxVSCROLL
			  );
		$txtCtrl->SetSelection(-1, -1);
		$txtCtrl->SetFocus;
		$self->{txtctrl} = $txtCtrl;
	}
	
	
	
	$vbox->Add($txtCtrl, 1, Wx::wxEXPAND);
	
	my $btnBox = Wx::BoxSizer->new( Wx::wxHORIZONTAL );
	my $pnlButtons =  Wx::Panel->new($self,
					-1,         # id
					[-1,-1],     # position
					[-1,-1],     # size
					0 # border style
					);

	if( $getData ) {
		#print "adding cancel\n";
		my $btnCancel = Wx::Button->new( $pnlButtons, Wx::wxID_CANCEL, "Cancel", [50,50]);
		Wx::Event::EVT_BUTTON( $self, $btnCancel, \&cancel_clicked  );		
		$btnBox->Add($btnCancel, 0, Wx::wxALIGN_BOTTOM | Wx::wxALIGN_RIGHT);
	}
	
	my $btnOK = Wx::Button->new( $pnlButtons, Wx::wxID_OK, "OK", [50,50]);
	Wx::Event::EVT_BUTTON( $self, $btnOK, \&ok_clicked );	
	
	$btnBox->Add($btnOK, 0, Wx::wxALIGN_BOTTOM | Wx::wxALIGN_RIGHT);


	$pnlButtons->SetSizer($btnBox);
	
	#$btnBox->Add( $pnlButtons, 0, Wx::wxALIGN_BOTTOM | Wx::wxALIGN_RIGHT | Wx::wxEXPAND);
	$vbox->Add( $pnlButtons, 0, Wx::wxALIGN_BOTTOM | Wx::wxALIGN_RIGHT);
	
	
	$self->SetSizer($vbox);
	
}

sub ok_clicked {
	my ($self) = @_;
	#print "OK Clicked\n";
	my $txt;
	if( $self->{txtctrl} ) {
		#print "have to return data: " . $self->{txtctrl}->GetValue;
		$txt = $self->{txtctrl}->GetValue;
	}
	$self->Hide();
	$self->Destroy;
	return $txt;
}

sub cancel_clicked {
	my ($self) = @_;
	#print "Cancel Clicked\n";
	$self->Hide();
	$self->Destroy;
	$self->{txtctrl}->SetValue("");
	
	return;
	
}
sub get_data {
	my( $self ) = @_;
	#print "Getting Data: " . $self->{txtctrl}->GetValue . "\n";
	return $self->{txtctrl}->GetValue;
	#my $txt =  $self->{txtctrl}->GetValue;
	#use Data::Dumper;
	#print Dumper($txt);
	#return $txt ;
	
}

1;