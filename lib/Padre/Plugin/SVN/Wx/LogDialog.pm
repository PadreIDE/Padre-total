package Padre::Plugin::SVN::Wx::LogDialog;


use 5.008;
use warnings;
use strict;

use Padre::Wx     ();


our @ISA = 'Wx::Frame';

sub new {
	my $class = shift;
	my $main = shift;
	my $filePath = shift;
	my $log = shift;
	
	my $self = $class->SUPER::new (
		$main,
		-1,
		'SVN Log',
		[200,300],
		[600,550],
	);
	
	$self->build_dialog($filePath, $log);
	
	return $self;
	
	
}


sub build_dialog {
	my ($self, $file, $log) = @_;
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
	
	print "file: $file\n";
	print "Log: $log\n";
	
	my $txtCtrl = Wx::TextCtrl->new(
                   $self, 
                   -1,
                   "$log", 
                   Wx::wxDefaultPosition, 
                   [-1,-1], 
                   Wx::wxTE_MULTILINE | Wx::wxHSCROLL | Wx::wxVSCROLL
                  );

	
	$vbox->Add($txtCtrl, 1, Wx::wxEXPAND);
	
	my $btnBox = Wx::BoxSizer->new( Wx::wxHORIZONTAL );
	my $pnlButtons =  Wx::Panel->new($self,
					-1,         # id
					[-1,-1],     # position
					[-1,-1],     # size
					0 # border style
					);


	
	my $btnOK = Wx::Button->new( $pnlButtons, -1, "OK", [50,50]);
	Wx::Event::EVT_BUTTON( $self, $btnOK, \&ok_clicked );

	$btnBox->Add( $pnlButtons, 0, Wx::wxALIGN_BOTTOM | Wx::wxALIGN_RIGHT | Wx::wxEXPAND);
	$vbox->Add( $btnBox, 0, Wx::wxALIGN_BOTTOM | Wx::wxALIGN_RIGHT);
	
	
	$self->SetSizer($vbox);
	
}

sub ok_clicked {
	my ($self) = @_;
	$self->Hide();
	$self->Destroy;
	return;
}

1;