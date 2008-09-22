package Padre::Wx::ToolBar;

use 5.008;
use strict;
use warnings;
use Params::Util qw{ _INSTANCE };
use Wx           ();
use Padre::Wx    ();

our $VERSION = '0.10';
our @ISA     = 'Wx::ToolBar';

sub new {
	my $class  = shift;
	my $parent = shift;
	my $self   = $class->SUPER::new(
		$parent,
		-1,
		Wx::wxDefaultPosition,
		Wx::wxDefaultSize,
		Wx::wxNO_BORDER | Wx::wxTB_HORIZONTAL | Wx::wxTB_FLAT | Wx::wxTB_DOCKABLE,
		5050,
	);

	# Automatically populate
	$self->AddTool( Wx::wxID_NEW,  '', Padre::Wx::bitmap('new'),  'New File'  ); 
	$self->AddTool( Wx::wxID_OPEN, '', Padre::Wx::bitmap('open'), 'Open File' ); 
	$self->AddTool( Wx::wxID_SAVE, '', Padre::Wx::bitmap('save'), 'Save File' );
	# $self->AddTool( Wx::wxID_CLOSE, '', Padre::Wx::bitmap('close'), 'Close File' );
	$self->AddSeparator;

	return $self;
}

sub refresh {
	my $self    = shift;
	my $doc     = shift;
	my $enabled = !! ( $doc and ( $doc->is_new or $doc->is_modified ) );
	$self->EnableTool( Wx::wxID_SAVE, $enabled );
	return 1;
}

1;
