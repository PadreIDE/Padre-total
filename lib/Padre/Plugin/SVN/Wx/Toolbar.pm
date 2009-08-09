package Padre::Plugin::SVN::Wx::Toolbar;

use 5.008;
use warnings;
use strict;

use Padre::Config ();
use Padre::Wx     ();



our @ISA     = 'Wx::ToolBar';


# NOTE: Something is wrong with dockable toolbars on Windows
#       so disable them for now.
use constant DOCKABLE => !Padre::Constant::WXWIN32;

sub new {
	my $class = shift;
	my $main  = shift;

	print ref($main);
	
	# Prepare the style
	my $style = Wx::wxTB_HORIZONTAL | Wx::wxTB_FLAT | Wx::wxTB_NODIVIDER | Wx::wxBORDER_NONE;
	if ( DOCKABLE and not $main->config->main_lockinterface ) {
		$style = $style | Wx::wxTB_DOCKABLE;
	}

	# Create the parent Wx object
	my $self = $class->SUPER::new(
		$main, -1,
		#Wx::wxDefaultPosition,
		#Wx::wxDefaultSize,
		#$style,
		#5050,
	);
	
	#print ref($self);
	
	# Default icon size is 16x15 for Wx, to use the 16x16 GPL
	# icon sets we need to be SLIGHTLY bigger.
	$self->SetToolBitmapSize( Wx::Size->new( 16, 16 ) );

	# toolbar id sequence generator
	# Toolbar likes only unique values. Do otherwise on your own risk.
	$self->{next_id} = 20000;	
	
	$self->{test} = $self->add_tool();

	$self->AddSeparator;	
		
	$self->Realize;
	
	return $self;
	
}

sub add_tool {
	my ( $self ) = @_;
	
	my $id = $self->{next_id}++;
	$self->AddTool(
		$id,
		'label',
		'./icons/edit-redo.png',
		'short help',
	);
		

	return $id;
	
}

sub refresh {
	my ($self) = @_;
	
	$self->EnableTool($self->{test}, 1);
	
	return;
}





1;