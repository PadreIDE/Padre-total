package Padre::Wx::Role::Storable;

# A role for wxWindow objects that provides integration with Storable.pm

use 5.008005;
use strict;
use warnings;
use Storable  ();
use Padre::Wx ();

our $VERSION = '0.62';

sub STORABLE_freeze {
	$_[0]->GetId
}

sub STORABLE_attach {
	Wx::Window->FindWindowById($_[0]);
}

1;
