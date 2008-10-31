package Padre::Wx::Output;

# Class for the output window at the bottom of Padre.
# This currently has very little customisation code in it,
# but that will change in future.

use 5.008;
use strict;
use warnings;
use Params::Util ();
use Padre::Wx    ();

use base 'Wx::TextCtrl';

our $VERSION = '0.14';

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

	# Do custom startup stuff here
	$self->clear;
	$self->AppendText('No output');

	return $self;
}

# A convenience not provided by the original version
sub SetBackgroundColour {
	my $self = shift;
	my $arg  = shift;
	if ( defined Params::Util::_STRING($arg) ) {
		$arg = Wx::Colour->new($arg);
	}
	return $self->SUPER::SetBackgroundColour($arg);
}

sub clear {
	my $self = shift;
	$self->SetBackgroundColour('#FFFFFF');
	$self->Remove( 0, $self->GetLastPosition );
	return 1;
}

1;
