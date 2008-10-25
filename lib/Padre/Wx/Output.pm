package Padre::Wx::Output;

# Class for the output window at the bottom of Padre.
# This currently has very little customisation code in it,
# but that will change in future.

use 5.008;
use strict;
use warnings;
use Padre::Wx ();

use base 'Wx::TextCtrl';

sub new {
	my $class  = shift;
	my $parent = shift;
	my $self   = $class->SUPER::new(
		$parent,
		-1,
		"", 
		Wx::wxDefaultPosition,
		Wx::wxDefaultSize,
		Wx::wxTE_READONLY | Wx::wxTE_MULTILINE | Wx::wxTE_DONTWRAP | Wx::wxNO_FULL_REPAINT_ON_RESIZE,
	);

	# By definition the output window is not shown by default.
	# Therefore, we should Freeze the widget to stop it attempt to render anything,
	# which has been a cause of weird visual artifacts in the past.
	$self->Freeze;

	# Do custom startup stuff here

	return $self;
}

1;
