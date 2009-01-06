package Padre::Wx::AuiManager;

# Sub-class of Wx::AuiManager that implements various custom
# tweaks and behaviours.

use strict;
use warnings;
use Params::Util qw{_INSTANCE};
use Padre::Wx    ();

our $VERSION = '0.24';

# Due to an overly simplistic implementation at the C level,
# Wx::AuiManager is only a SCALAR reference and cannot be
# sub-classed.
# Instead, we will do inheritance by composition.
use Class::Adapter::Builder
	ISA      => 'Wx::AuiManager',
	AUTOLOAD => 1;

# The custom AUI Manager takes the parent window as a param
sub new {
	my $class  = shift;
	my $object = Wx::AuiManager->new;
	my $self   = $class->SUPER::new( $object );

	# Locale caption gettext values
	$self->{caption} = {};

	# Set the managed window
	$self->SetManagedWindow($_[0]);

	# Set/fix the flags
	# Do NOT use hints other than Rectangle on Linux/GTK
	# or the app will crash.
	my $flags = $self->GetFlags;
	$flags &= ~Wx::wxAUI_MGR_TRANSPARENT_HINT;
	$flags &= ~Wx::wxAUI_MGR_VENETIAN_BLINDS_HINT;
	$self->SetFlags( $flags ^ Wx::wxAUI_MGR_RECTANGLE_HINT );

	return $self;
}

sub caption_gettext {
	my $self = shift;
	$self->{caption}->{$_[0]} = $_[1];
	$self->GetPane($_[0])->Caption( Wx::gettext($_[1]) );
	return 1;
}

sub relocale {
	my $self = shift;

	# Update the pane captions
	foreach my $name ( sort keys %{ $self->{caption} } ) {
		my $pane = $self->GetPane($name) or next;
		$pane->Caption( Wx::gettext($self->{caption}->{$name}) );
	}

	return $self;
}

1;
